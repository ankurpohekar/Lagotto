class Api::V5::ArticlesController < Api::V5::BaseController

  def index
    # Filter by source parameter, filter out private sources unless admin
    # Load articles from ids listed in query string, use type parameter if present
    # Translate type query parameter into column name
    # Limit number of ids to 50
    source_ids = get_source_ids(params[:source])
    collection = ArticleDecorator.includes(:retrieval_statuses).where({ :retrieval_statuses => { :source_id => source_ids }})

    if params[:ids]
      if params[:type]
        type = { "doi" => "doi",
                 "pmid" => "pub_med",
                 "pmcid" => "pub_med_central",
                 "mendeley" => "mendeley" }.assoc(params[:type])

        type = type.nil? ? Article.uid : type[1]
      else
        type = Article.uid
      end

      ids = params[:ids].nil? ? nil : params[:ids].split(",").map { |id| Article.clean_id(id) }
      collection = collection.where({ :articles => { type.to_sym => ids }})
    elsif params[:q]
      collection = collection.query(params[:q])
    end

    if params[:class_name]
      @class_name = params[:class_name]
      collection = collection.includes(:alerts)
      if @class_name == "All Alerts"
        collection = collection.where("alerts.unresolved = 1 ")
      else
        collection = collection.where("alerts.unresolved = 1 AND alerts.class_name = ?", @class_name)
      end
    end

    collection = collection.order_articles(params[:order])
    collection = collection.paginate(:page => params[:page])
    @articles = collection.decorate(:context => { :info => params[:info], :source => params[:source] })
  end

  protected

  # Filter by source parameter, filter out private sources unless staff or admin
  def get_source_ids(source_names)
    if source_names && current_user.try(:admin_or_staff?)
      source_ids = Source.where("lower(name) in (?)", source_names.split(",")).order("group_id, sources.display_name").pluck(:id)
    elsif source_names
      source_ids = Source.where("private = 0 AND lower(name) in (?)", source_names.split(",")).order("group_id, sources.display_name").pluck(:id)
    elsif current_user.try(:admin_or_staff?)
      source_ids = Source.order("group_id, sources.display_name").pluck(:id)
    else
      source_ids = Source.where("private = 0").order("group_id, sources.display_name").pluck(:id)
    end
  end
end