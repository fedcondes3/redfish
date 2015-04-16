require File.expand_path('../helper', __FILE__)

class TestContext < Redfish::TestCase

  def test_basic_workflow
    domain_name = 'appserver'
    domain_admin_port = 4848
    domain_secure = true
    domain_username = 'admin'
    domain_password_file = '/etc/glassfish/password'

    context = Redfish::Context.new(domain_name, domain_admin_port, domain_secure, domain_username, domain_password_file)

    assert_equal context.domain_name, domain_name
    assert_equal context.domain_admin_port, domain_admin_port
    assert_equal context.domain_secure, domain_secure
    assert_equal context.domain_username, domain_username
    assert_equal context.domain_password_file, domain_password_file

    assert !context.property_cache?

    context.cache_properties('a' => '1', 'b' => '2')

    assert context.property_cache?
    assert_equal context.property_cache['a'], '1'
    assert_equal context.property_cache['b'], '2'
  end
end
