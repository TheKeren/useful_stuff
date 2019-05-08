require_relative './spec_helper'
require_relative './constants'

describe ecs_cluster('kitchen-platform-test') do
  it { should exist }
  it { should be_active }
  its(:cluster_arn) { should eq $ecs_id }
end


describe iam_role('kitchen-platform-test-ecs-admin') do
  it { should exist }
  it { should have_iam_policy('kitchen-platform-test-ecs-admin') }
  its(:arn) { should eq $instance_role_arn }
  it { should be_allowed_action('logs:PutLogEvents').resource_arn( $brand_log_group_arn ) }
  it { should be_allowed_action('logs:CreateLogStream').resource_arn( $brand_log_group_arn ) } 
  it { should be_allowed_action('ecs:RegisterContainerInstance').resource_arn( $ecs_id ) }
  it { should be_allowed_action('ecs:RegisterContainerInstance').resource_arn( $ecs_id + '/*' ) }
  it { should be_allowed_action('ecs:DescribeClusters').resource_arn($ecs_id) }
  it { should be_allowed_action('ecs:DescribeClusters').resource_arn($ecs_id + '/*') }
#  it { should be_allowed_action('ecs:DeregisterContainerInstance').resource_arn($ecs_id) }
  it { should be_allowed_action('ecs:DeregisterContainerInstance').resource_arn($ecs_id + '/*') }
#  it { should be_allowed_action('ecs:UpdateContainerAgent').resource_arn($ecs_id) }
#  it { should be_allowed_action('ecs:StopTask').resource_arn($ecs_id) }
#  it { should be_allowed_action('ecs:StartTelemetrySession').resource_arn($ecs_id) }
#  it { should be_allowed_action('ecs:StartTask').resource_arn($ecs_id) }
#  it { should be_allowed_action('ecs:RunTask').resource_arn($ecs_id) }
#  it { should be_allowed_action('ecs:Poll').resource_arn($ecs_id) }
#  it { should be_allowed_action('ecs:ListTasks').resource_arn($ecs_id) }
#  it { should be_allowed_action('ecs:DescribeTasks').resource_arn($ecs_id) }
#  it { should be_allowed_action('ecs:DescribeContainerInstances').resource_arn($ecs_id) }
#  it { should be_allowed_action('ecs:CreateCluster').resource_arn($ecs_id) }
end

describe security_group('kitchen-platform-test') do
  it { should exist }
  its(:outbound) { should be_opened }
  its(:inbound) { should be_opened.for($placeholder_sg_id) }
  its(:inbound) { should be_opened(22).protocol('tcp').for('10.0.0.1/32') }
  it { should have_tag('Name').value('kitchen-platform-test') }
  it { should have_tag('branch').value('master') }
  it { should have_tag('brand').value('platform') }
  it { should have_tag('environment').value('test') }
  it { should have_tag('provisioner').value('terraform') }
  it { should have_tag('stack').value('tf-ecs') }
  it { should have_tag('vendor').value('kitchen') }
  its(:group_id) { should eq $ecs_cluster_sg_id }
end

describe security_group('kitchen-platform-test-efs') do
  it { should exist }
  its(:inbound) { should be_opened(2049).protocol('tcp').for($ecs_cluster_sg_id) }
  it { should have_tag('Name').value('kitchen-platform-test-efs') }
  it { should have_tag('branch').value('master') }
  it { should have_tag('brand').value('platform') }
  it { should have_tag('environment').value('test') }
  it { should have_tag('provisioner').value('terraform') }
  it { should have_tag('stack').value('tf-ecs') }
  it { should have_tag('vendor').value('kitchen') }
  its(:group_id) { should eq $efs_sg_id }
end

describe efs('kitchen-platform-test-efs') do
  it { should exist }
  its(:file_system_id) { should eq $efs_id }
  its(:number_of_mount_targets) { should eq 2 }
  it { should have_tag('Name').value('kitchen-platform-test-efs') }
  it { should have_tag('branch').value('master') }
  it { should have_tag('brand').value('platform') }
  it { should have_tag('environment').value('test') }
  it { should have_tag('provisioner').value('terraform') }
  it { should have_tag('stack').value('tf-ecs') }
  it { should have_tag('vendor').value('kitchen') }
end

describe autoscaling_group('kitchen-platform-test') do
  it { should exist }
  it { should have_launch_configuration($launch_config_name) }
  its(:min_size) { should eq 2 }
  its(:max_size) { should eq 4 }
  its(:desired_capacity) { should eq 2 }
  its(:default_cooldown) { should eq 300 }
  it { should have_tag('Name').value('kitchen-platform-test') }
  it { should have_tag('branch').value('master') }
  it { should have_tag('brand').value('platform') }
  it { should have_tag('environment').value('test') }
  it { should have_tag('provisioner').value('terraform') }
  it { should have_tag('stack').value('tf-ecs') }
end

describe launch_configuration($launch_config_name) do
  it { should exist }
  it { should have_security_group($ecs_cluster_sg_id) }
  its(:image_id) { should eq $ecs_ami_id }
  its(:key_name) { should eq 'terraform_test' }
  its(:security_groups) { should eq [$ecs_cluster_sg_id] }
  its(:iam_instance_profile) { should eq 'kitchen-platform-test-ecs-admin' }
end

describe cloudwatch_alarm('kitchen-platform-test-cpu-high') do
  it { should exist }
  it { should belong_to_metric('CPUUtilization').namespace('AWS/ECS') }
  its(:alarm_actions) { should eq [$cpu_high_alarm_action] }
  its(:threshold) { should eq 80.0 }
end

describe cloudwatch_alarm('kitchen-platform-test-scaleup-ecs_mem') do
  it { should exist }
  it { should belong_to_metric('MemoryReservation').namespace('AWS/ECS') }
  its(:alarm_actions) { should eq [$mem_high_alarm_action] }
  its(:threshold) { should eq 70.0 }
end
