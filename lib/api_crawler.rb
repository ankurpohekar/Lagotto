require 'net/http'
require 'json'

class ApiCrawler
  attr_reader :url, :output_file

  def self.crawl
    stop_on_page = (ENV["STOP_ON_PAGE"] || 10).to_i
    crawl_events stop_on_page: stop_on_page
    crawl_references stop_on_page: stop_on_page
    crawl_works stop_on_page: stop_on_page
  end

  def self.crawl_works(crawl_options={})
    output_file = ENV["OUTPUT"] || Rails.root.join("tmp/works.jsondump")
    new(
      url: "http://#{ENV['HOST']}/api/works",
      output_file: output_file,
      benchmark_file: Rails.root.join("#{output_file}.benchmarks")
    ).crawl(crawl_options)
  end

  def self.crawl_events(crawl_options={})
    output_file = ENV["OUTPUT"] || Rails.root.join("tmp/events.jsondump")
    new(
      url: "http://#{ENV['HOST']}/api/events",
      output_file: output_file,
      benchmark_file: Rails.root.join("#{output_file}.benchmarks")
    ).crawl(crawl_options)
  end

  def self.crawl_references(crawl_options={})
    output_file = ENV["OUTPUT"] || Rails.root.join("tmp/references.jsondump")
    new(
      url: "http://#{ENV['HOST']}/api/events",
      output_file: output_file,
      benchmark_file: Rails.root.join("#{output_file}.benchmarks")
      ).crawl(crawl_options)
  end

  def initialize(options={})
    @url = options[:url] || raise(ArgumentError, "Must supply :url")
    @output_file = options[:output_file] || raise(ArgumentError, "Must supply :output_file")
    @benchmark_file = options[:benchmark_file]
  end

  def crawl(options={})
    @stop_on_page = options[:stop_on_page] || Float::INFINITY
    @output = File.open(output_file, "wb")
    @output.sync = true

    if @benchmark_file
      @benchmark_output = File.open(@benchmark_file, "wb")
      @benchmark_output.sync = true
    end

    next_uri = URI.parse(@url)

    while next_uri do
      benchmark(next_uri) do
        http = Net::HTTP.new(next_uri.host, next_uri.port)
        http.open_timeout = 3600
        http.read_timeout = 3600
        response = http.start do |http|
          path = if next_uri.query
            next_uri.path.to_s + "?" + next_uri.query
          else
            next_uri.path.to_s
          end
          http.get path
        end
        response_body = response.body
        next_uri = process_response_body_and_get_next_page_uri(response_body)
      end
    end
  ensure
    @output.close if @output
  end

  private

  def benchmark(uri, &blk)
    if @benchmark_output
      n = Time.now
      yield
      duration = Time.now - n
      @benchmark_output.puts "#{uri} took #{duration} seconds"
    else
      yield
    end
  end

  def process_response_body_and_get_next_page_uri(response_body)
    json = JSON.parse(response_body)
    @output.puts response_body

    meta = json["meta"] || raise("Missing meta element in:\n #{json.inspect}")
    page = meta["page"] || raise("Missing page inside of meta element in:\n #{meta.inspect}")
    total_pages = meta["total_pages"] || raise("Missing total_pages inside of meta element in:\n #{meta.inspect}")

    if page <= total_pages && page <= @stop_on_page
      next_uri = URI.parse(@url)
      next_uri.query = "page=#{page+1}"
      next_uri
    else
      nil
    end
  end

end
