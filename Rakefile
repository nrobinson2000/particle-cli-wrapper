# TODO: create install script for OSX and Linux
# echo '{"hostname":"test","domainname":"example.com"}' | python -c 'import json,sys;obj=json.load(sys.stdin);print obj[0]["hostname"]'

require 'digest'
require 'aws-sdk'
require 'json'

PRODUCT_NAME = 'cli'
BINARY_NAME = 'particle'
BUCKET_NAME = 'binaries.particle.io'
ASSETS_HOST = 'binaries.particle.io'

TARGETS = [
  {os: 'windows', arch: '386'},
  {os: 'windows', arch: 'amd64'},
  {os: 'darwin', arch: 'amd64'},
  {os: 'linux', arch: 'arm', goarm: '6'},
  {os: 'linux', arch: 'amd64'},
  {os: 'linux', arch: '386', go386: '387'},
]

VERSION = `./version`.chomp
dirty = `git status 2> /dev/null | tail -n1`.chomp != 'nothing to commit, working tree clean'
CHANNEL = dirty ? 'dirty' : `git rev-parse --abbrev-ref HEAD`.chomp
LABEL = "particle-cli-wrapper/#{VERSION} (#{CHANNEL})"
REVISION=`git log -n 1 --pretty=format:"%H"`

task :sha do
  puts sha_digest("dist/linux/amd64/particle")
end

task :manifest do
  puts JSON.dump(manifest)
end

desc "build particle-cli-wrapper"
task :build do
  puts "Building #{LABEL}..."
  FileUtils.mkdir_p 'dist'
  TARGETS.each do |target|
    puts "  * #{target[:os]}-#{target[:arch]}"
    build(target)
  end
end

desc "release particle-cli-wrapper"
task :release => :build do
  abort 'branch is dirty' if CHANNEL == 'dirty'
  abort "#{CHANNEL} not a channel branch (dev/beta/master)" unless %w(dev beta master).include?(CHANNEL)
  puts "Releasing #{LABEL}..."
  cache_control = "public,max-age=31536000"
  TARGETS.each do |target|
    puts "  * #{target[:os]}-#{target[:arch]}"
    from = local_path(target[:os], target[:arch])
    to = remote_path(target[:os], target[:arch])
    upload_file(from, to, content_type: 'binary/octet-stream', cache_control: cache_control)
    upload_file(from + '.gz', to + '.gz', content_type: 'binary/octet-stream', content_encoding: 'gzip', cache_control: cache_control)
    upload(sha_digest(from), to + ".sha1", content_type: 'text/plain', cache_control: cache_control)
  end
  upload_manifest()
  notify_rollbar
  puts "Released #{VERSION}"
end

def build(target)
  path = local_path(target[:os], target[:arch])
  ldflags = "-X=main.Version=#{VERSION} -X=main.Channel=#{CHANNEL}"
  if target[:os] === 'darwin'
    ldflags += " -s"
  end
  args = ["-o", "#{path}", "-ldflags", "\"#{ldflags}\""]
  unless target[:os] === 'windows'
    args += ["-a", "-tags", "netgo"]
  end
  vars = ["GOOS=#{target[:os]}", "GOARCH=#{target[:arch]}"]
  vars << "GO386=#{target[:go386]}" if target[:go386]
  vars << "GOARM=#{target[:goarm]}" if target[:goarm]
  ok = system("#{vars.join(' ')} go build #{args.join(' ')}")
  exit 1 unless ok
  #if target[:os] === 'windows'
  #  # sign executable
  #  ok = system "osslsigncode -pkcs12 resources/exe/particle-codesign-cert.pfx \
  #  -pass '#{ENV['PARTICLE_WINDOWS_SIGNING_PASS']}' \
  #  -n 'Particle CLI' \
  #  -i https://www.particle.io/ \
  #  -in #{path} \
  #  -out #{path} > /dev/null"
  #  unless ok
  #    $stderr.puts "Unable to sign Windows binaries, please follow the full release instructions"
  #    $stderr.puts "https://github.com/particle-iot/particle-cli-wrapper/blob/master/RELEASE-FULL.md#windows-release"
  #    exit 2
  #  end
  #end
  gzip(path)
end

def gzip(path)
  system("gzip --keep -f #{path}")
end

def sha_digest(path)
  Digest::SHA1.file(path).hexdigest
end

def local_path(os, arch)
  ext = ".exe" if os === 'windows'
  "./dist/#{os}/#{arch}/#{BINARY_NAME}#{ext}"
end

def remote_path(os, arch)
  ext = ".exe" if os === 'windows'
  "#{PRODUCT_NAME}/#{CHANNEL}/#{VERSION}/#{os}/#{arch}/#{BINARY_NAME}#{ext}"
end

def remote_url(os, arch)
  "https://#{ASSETS_HOST}/#{remote_path(os, arch)}"
end

def manifest
  return @manifest if @manifest
  @manifest = {
    released_at: Time.now,
    version: VERSION,
    channel: CHANNEL,
    builds: {}
  }
  TARGETS.each do |target|
    @manifest[:builds][target[:os]] ||= {}
    @manifest[:builds][target[:os]][target[:arch]] = {
      url: remote_url(target[:os], target[:arch]),
      sha1: sha_digest(local_path(target[:os], target[:arch]))
    }
  end

  @manifest
end

def s3_client
  @s3_client ||= Aws::S3::Client.new(region: 'us-east-1', access_key_id: ENV['PARTICLE_CLI_RELEASE_ACCESS'], secret_access_key: ENV['PARTICLE_CLI_RELEASE_SECRET'])
end

def upload_file(local, remote, opts={})
  upload(File.new(local), remote, opts)
end

def upload(body, remote, opts={})
  s3_client.put_object({
    key: remote,
    body: body,
    acl: 'public-read',
    bucket: BUCKET_NAME
  }.merge(opts))
end

def upload_manifest
  puts 'uploading manifest...'
  upload(JSON.dump(manifest), "#{PRODUCT_NAME}/#{CHANNEL}/manifest.json", content_type: 'application/json', cache_control: "public,max-age=60")
end

def notify_rollbar
  unless ENV['ROLLBAR_TOKEN']
    $stderr.puts 'ROLLBAR_TOKEN not set, skipping rollbar deploy notification'
    return
  end
  Net::HTTP.post_form(URI.parse('https://api.rollbar.com/api/1/deploy/'),
                      environment: CHANNEL,
                      local_username: `whoami`.chomp,
                      revision: REVISION,
                      access_token: ENV['ROLLBAR_TOKEN'])
end
