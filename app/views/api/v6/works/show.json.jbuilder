json.meta do
  json.status @status || "ok"
  json.set! :"message-type", "work"
  json.set! :"message-version", "6.0.0"
end

json.work do
  json.cache! ['v6', @work], skip_digest: true do
    json.(@work, :id, :title, :issued, :container_title, :volume, :page, :issue, :publisher_id, :doi, :url, :pmid, :pmcid, :scp, :wos, :ark, :metrics, :update_date)
  end
end
