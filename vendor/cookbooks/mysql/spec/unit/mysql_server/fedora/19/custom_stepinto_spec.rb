require 'spec_helper'

describe 'stepped into mysql_test_custom::server on fedora-19' do
  let(:fedora_19_custom_run) do
    ChefSpec::Runner.new(
      :step_into => 'mysql_service',
      :platform => 'fedora',
      :version => '19'
      ) do |node|
      node.set['mysql']['service_name'] = 'fedora_19_custom'
      node.set['mysql']['port'] = '3308'
      node.set['mysql']['data_dir'] = '/data'
      node.set['mysql']['template_source'] = 'custom.erb'
      node.set['mysql']['allow_remote_root'] = true
      node.set['mysql']['remove_anonymous_users'] = false
      node.set['mysql']['remove_test_database'] = false
      node.set['mysql']['root_network_acl'] = ['10.9.8.7/6', '1.2.3.4/5']
      node.set['mysql']['server_root_password'] = 'YUNOSETPASSWORD'
      node.set['mysql']['server_debian_password'] = 'postinstallscriptsarestupid'
      node.set['mysql']['server_repl_password'] = 'syncmebabyonemoretime'
    end.converge('mysql_test_custom::server')
  end

  let(:my_cnf_5_5_content_fedora_19) do
    'This my template. There are many like it but this one is mine.'
  end

  let(:grants_sql_content_custom_fedora_19) do
    "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%' identified by 'syncmebabyonemoretime';
GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY 'YUNOSETPASSWORD' WITH GRANT OPTION;
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('YUNOSETPASSWORD');
SET PASSWORD FOR 'root'@'127.0.0.1' = PASSWORD('YUNOSETPASSWORD');
GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.9.8.7/6' IDENTIFIED BY 'YUNOSETPASSWORD' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'1.2.3.4/5' IDENTIFIED BY 'YUNOSETPASSWORD' WITH GRANT OPTION;"
  end

  before do
    stub_command("/usr/bin/mysql -u root -e 'show databases;'").and_return(true)
  end

  context 'when using default parameters' do
    it 'creates mysql_service[fedora_19_custom]' do
      expect(fedora_19_custom_run).to create_mysql_service('fedora_19_custom').with(
        :parsed_version => '5.5',
        :parsed_port => '3308',
        :parsed_data_dir => '/data'
        )
    end

    it 'steps into mysql_service and installs package[community-mysql-server]' do
      expect(fedora_19_custom_run).to install_package('community-mysql-server')
    end

    it 'steps into mysql_service and creates directory[/etc/my.cnf.d]' do
      expect(fedora_19_custom_run).to create_directory('/etc/my.cnf.d').with(
        :owner => 'mysql',
        :group => 'mysql',
        :mode => '0750',
        :recursive => true
        )
    end

    it 'steps into mysql_service and creates directory[/var/run/mysqld]' do
      expect(fedora_19_custom_run).to create_directory('/var/run/mysqld').with(
        :owner => 'mysql',
        :group => 'mysql',
        :mode => '0755',
        :recursive => true
        )
    end

    it 'steps into mysql_service and creates directory[/data]' do
      expect(fedora_19_custom_run).to create_directory('/data').with(
        :owner => 'mysql',
        :group => 'mysql',
        :mode => '0755',
        :recursive => true
        )
    end

    it 'steps into mysql_service and creates template[/etc/my.cnf]' do
      expect(fedora_19_custom_run).to create_template('/etc/my.cnf').with(
        :owner => 'mysql',
        :group => 'mysql',
        :mode => '0600'
        )
    end

    it 'steps into mysql_service and renders file[/etc/my.cnf]' do
      expect(fedora_19_custom_run).to render_file('/etc/my.cnf').with_content(
        my_cnf_5_5_content_fedora_19
        )
    end

    it 'steps into mysql_service and creates service[mysqld]' do
      expect(fedora_19_custom_run).to start_service('mysqld')
      expect(fedora_19_custom_run).to enable_service('mysqld')
    end

    it 'steps into mysql_service and runs execute[wait for mysql]' do
      expect(fedora_19_custom_run).to run_execute('wait for mysql')
    end

    it 'steps into mysql_service and creates template[/etc/mysql_grants.sql]' do
      expect(fedora_19_custom_run).to create_template('/etc/mysql_grants.sql').with(
        :owner => 'root',
        :group => 'root',
        :mode => '0600'
        )
    end

    it 'steps into mysql_service and renders file[/etc/mysql_grants.sql]' do
      expect(fedora_19_custom_run).to render_file('/etc/mysql_grants.sql').with_content(
        grants_sql_content_custom_fedora_19
        )
    end

    it 'steps into mysql_service and creates execute[install-grants]' do
      expect(fedora_19_custom_run).to_not run_execute('install-grants').with(
        :command => '/usr/bin/mysql -u root -pYUNOSETPASSWORD < /etc/mysql_grants.sql'
        )
    end

    it 'steps into mysql_service and creates bash[move mysql data to datadir]' do
      expect(fedora_19_custom_run).to_not run_bash('move mysql data to datadir')
    end

    it 'steps into mysql_service and creates execute[assign-root-password]' do
      expect(fedora_19_custom_run).to run_execute('assign-root-password').with(
        :command => '/usr/bin/mysqladmin -u root password YUNOSETPASSWORD'
        )
    end

    it 'steps into mysql_service and writes log[notify restart]' do
      expect(fedora_19_custom_run).to write_log('notify restart')
    end

    it 'steps into mysql_service and writes log[notify reload]' do
      expect(fedora_19_custom_run).to write_log('notify reload')
    end
  end

  context 'when using non-default package_version parameter' do
    let(:package_version) { '5.5.35-1.el6' }
    let(:fedora_19_custom_run) do
      ChefSpec::Runner.new(
        :step_into => 'mysql_service',
        :platform => 'fedora',
        :version => '19'
        ) do |node|
        node.set['mysql']['service_name'] = 'fedora_19_custom'
        node.set['mysql']['port'] = '3308'
        node.set['mysql']['data_dir'] = '/data'
        node.set['mysql']['template_source'] = 'custom.erb'
        node.set['mysql']['allow_remote_root'] = true
        node.set['mysql']['remove_anonymous_users'] = false
        node.set['mysql']['remove_test_database'] = false
        node.set['mysql']['root_network_acl'] = ['10.9.8.7/6', '1.2.3.4/5']
        node.set['mysql']['server_root_password'] = 'YUNOSETPASSWORD'
        node.set['mysql']['server_debian_password'] = 'postinstallscriptsarestupid'
        node.set['mysql']['server_repl_password'] = 'syncmebabyonemoretime'
        node.set['mysql']['server_package_version'] = package_version
      end.converge('mysql_test_custom::server')
    end

    it 'creates mysql_service[fedora_19_custom] with correct package_version' do
      expect(fedora_19_custom_run).to create_mysql_service('fedora_19_custom').with(
        :parsed_version => '5.5',
        :parsed_port => '3308',
        :parsed_data_dir => '/data',
        :parsed_package_version => package_version
        )
    end

    it 'steps into mysql_service and installs package[community-mysql-server]' do
      expect(fedora_19_custom_run).to install_package('community-mysql-server').with(:version => package_version)
    end
  end

  context 'when using non-default package_action parameter' do
    let(:package_action) { 'upgrade' }
    let(:fedora_19_custom_run) do
      ChefSpec::Runner.new(
        :step_into => 'mysql_service',
        :platform => 'fedora',
        :version => '19'
        ) do |node|
        node.set['mysql']['service_name'] = 'fedora_19_custom'
        node.set['mysql']['port'] = '3308'
        node.set['mysql']['data_dir'] = '/data'
        node.set['mysql']['template_source'] = 'custom.erb'
        node.set['mysql']['allow_remote_root'] = true
        node.set['mysql']['remove_anonymous_users'] = false
        node.set['mysql']['remove_test_database'] = false
        node.set['mysql']['root_network_acl'] = ['10.9.8.7/6', '1.2.3.4/5']
        node.set['mysql']['server_root_password'] = 'YUNOSETPASSWORD'
        node.set['mysql']['server_debian_password'] = 'postinstallscriptsarestupid'
        node.set['mysql']['server_repl_password'] = 'syncmebabyonemoretime'
        node.set['mysql']['server_package_action'] = package_action
      end.converge('mysql_test_custom::server')
    end

    it 'creates mysql_service[fedora_19_custom] with correct package_action' do
      expect(fedora_19_custom_run).to create_mysql_service('fedora_19_custom').with(
        :parsed_version => '5.5',
        :parsed_port => '3308',
        :parsed_data_dir => '/data',
        :parsed_package_action => package_action
        )
    end

    it 'steps into mysql_service and upgrades package[community-mysql-server]' do
      expect(fedora_19_custom_run).to upgrade_package('community-mysql-server')
    end
  end
end
