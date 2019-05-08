require_relative './spec_helper'
require_relative './constants'

#describe elasticache('platfor-red-kit-test') do
#  it { should exist }
#  it { should be_available }
#  its(:configuration_endpoint) { should eq $redis_endpoint}
#  its(:cache_cluster_id) { should eq $redis_id}
#  it { should have_cache_parameter_group('default.redis5.0') }
#  it { should have_security_group($redis_sg_id) }
#  it { should belong_to_cache_subnet_group($redis_subnet_group) }
#  it { should belong_to_vpc('infrastructure-testing') }
#  its(:engine) { should eq 'redis' }
#  its(:engine_version) { should eq '5.0.0' }
#  its(:num_cache_nodes) { should eq '2' }
#  its(:preferred_availability_zone)
#  its(:preferred_maintenance_window) { should eq 'sun:05:00-sun:09:00' }
#  its(:auto_minor_version_upgrade) { should eq 'true' }
#  its(:snapshot_retention_limit) { should eq '1'}
#end

describe elasticache('platfor-mem-kit-test') do
  it { should exist }
  it { should be_available }
  its(:cache_cluster_id) { should eq $memcached_id}
  it { should have_cache_parameter_group('default.memcached1.5') }
  it { should have_security_group($memcached_sg_id) }
  it { should belong_to_cache_subnet_group($memcached_subnet_group) }
  it { should belong_to_vpc('infrastructure-testing') }
  its(:engine) { should eq 'memcached' }
  its(:engine_version) { should eq '1.5.10' }
  its(:num_cache_nodes) { should eq 1 }
  its(:preferred_availability_zone) { should eq 'eu-central-1b' }
end

describe security_group('platform-red-kitchen-test') do
  it { should exist }
  its(:outbound) { should be_opened }
  its(:inbound) { should be_opened.for($placeholder_sg_id) }
  it { should have_tag('Name').value('platform-red-kitchen-test') }
  it { should have_tag('brand').value('platform') }
  it { should have_tag('environment').value('test') }
  it { should have_tag('provisioner').value('terraform') }
  it { should have_tag('stack').value('kitchen-terraform') }
  it { should have_tag('component').value('red-kitchen') }
  its(:group_id) { should eq $redis_sg_id }
end

describe security_group('platform-red-cluster-kitchen-test') do
  it { should exist }
  its(:outbound) { should be_opened }
  its(:inbound) { should be_opened.for($placeholder_sg_id) }
  it { should have_tag('Name').value('platform-red-cluster-kitchen-test') }
  it { should have_tag('brand').value('platform') }
  it { should have_tag('environment').value('test') }
  it { should have_tag('provisioner').value('terraform') }
  it { should have_tag('stack').value('kitchen-terraform') }
  it { should have_tag('component').value('red-cluster-kitchen') }
  its(:group_id) { should eq $redis_cluster_sg_id }
end

describe security_group('platform-mem-kitchen-test') do
  it { should exist }
  its(:outbound) { should be_opened }
  its(:inbound) { should be_opened.for($placeholder_sg_id) }
  it { should have_tag('Name').value('platform-mem-kitchen-test') }
  it { should have_tag('brand').value('platform') }
  it { should have_tag('environment').value('test') }
  it { should have_tag('provisioner').value('terraform') }
  it { should have_tag('stack').value('kitchen-terraform') }
  it { should have_tag('component').value('mem-kitchen') }
  its(:group_id) { should eq $memcached_sg_id }
end
