ESpec.configure fn(config) ->
  config.before fn(tags) ->
    {:shared, port: 8081, tags: tags}
  end

  config.finally fn(_shared) ->
    :ok
  end
end
