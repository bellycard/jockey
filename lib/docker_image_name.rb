class DockerImageName
  def self.image_parts(image_string)
    # aws-east1-docker-registry01.bellycard.com:4046/campaign-service:7d790648ebccaae6e273441c67e6ff1b50f87524
    # paulczar/asgard:latest
    # paulczar/asgard
    # asgard:latest
    # asgard
    return {} if image_string.nil?
    parts = {}
    parts[:repo] = image_string.split('/').first if image_string.include?('/')
    image = image_string.split('/').last
    parts[:tag] = image.split(':').last if image.include?(':')
    parts[:name] = image.split(':').first
    parts
  end
end
