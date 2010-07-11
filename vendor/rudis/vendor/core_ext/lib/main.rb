# I fixed ruby loadpaths
def require_local(filename)
  require File.expand_path(
    File.join(
      File.dirname(
        caller.first.split(':').first
      ),
      *filename.split('/')
    )
  )
end
