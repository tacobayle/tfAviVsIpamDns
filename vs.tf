data "avi_cloud" "default_cloud" {
  name = var.avi_cloud
}

data "avi_tenant" "tenant" {
  name = var.avi_tenant
}

data "avi_network" "network_vip" {
  name = var.network_name
  cloud_ref = data.avi_cloud.default_cloud.id
}

output "networkaddr" {
  value = tolist(tolist(tolist(data.avi_network.network_vip.configured_subnets)[0].prefix)[0].ip_addr)[0].addr
}

output "networktype" {
  value = tolist(tolist(tolist(data.avi_network.network_vip.configured_subnets)[0].prefix)[0].ip_addr)[0].type
}

output "networkmask" {
  value = tolist(tolist(data.avi_network.network_vip.configured_subnets)[0].prefix)[0].mask
}

data "avi_sslkeyandcertificate" "ssl_cert1" {
  name = var.vs["sslCert"]
}

data "avi_sslprofile" "ssl_profile1" {
  name = var.vs["sslProfile"]
}

data "avi_applicationprofile" "application_profile1" {
  name = var.vs["applicationProfile"]
}

data "avi_networkprofile" "network_profile1" {
  name = var.vs["networkProfile"]
}


resource "avi_healthmonitor" "hm" {
  name = var.healthmonitor.name
  tenant_ref = data.avi_tenant.tenant.id
  type = var.healthmonitor.type
  receive_timeout = var.healthmonitor.receive_timeout
  failed_checks = var.healthmonitor.failed_checks
  send_interval = var.healthmonitor.send_interval
  successful_checks = var.healthmonitor.successful_checks
  http_monitor {
    http_request = var.healthmonitor.http_request
    http_response_code = var.http_response_code
  }
}

data "avi_healthmonitor" "hm" {
  depends_on = [avi_healthmonitor.hm]
  name = var.healthmonitor.name
}

resource "avi_pool" "lbpool" {
  depends_on = [avi_healthmonitor.hm]
  name = var.pool.name
  tenant_ref = data.avi_tenant.tenant.id
  lb_algorithm = var.pool.lb_algorithm
  cloud_ref = data.avi_cloud.default_cloud.id
  health_monitor_refs = ["${data.avi_healthmonitor.hm.id}"]
  dynamic servers {
    for_each = [for server in var.poolServers:{
      addr = server.ip
      type = server.type
      port = server.port
    }]
    content {
      ip {
        type = servers.value.type
        addr = servers.value.addr
      }
      port = servers.value.port
    }
  }
}

resource "avi_vsvip" "vsvip" {
  name = "vsvip-${var.vs.name}"
  tenant_ref = data.avi_tenant.tenant.id
  cloud_ref = data.avi_cloud.default_cloud.id
  vip {
    vip_id = 1
    auto_allocate_ip = true
    ipam_network_subnet {
      network_ref = data.avi_network.network_vip.id
      subnet {
        mask = tolist(tolist(data.avi_network.network_vip.configured_subnets)[0].prefix)[0].mask
        ip_addr {
          type = tolist(tolist(tolist(data.avi_network.network_vip.configured_subnets)[0].prefix)[0].ip_addr)[0].type
          addr = tolist(tolist(tolist(data.avi_network.network_vip.configured_subnets)[0].prefix)[0].ip_addr)[0].addr
        }
      }
    }
  }
  dns_info {
    fqdn = "${var.vs.name}.${var.domain_name}"
  }
}

data "avi_vsvip" "vsvip" {
  depends_on = [avi_vsvip.vsvip]
  name = "vsvip-${var.vs.name}"
}

data "avi_serviceenginegroup" "seg" {
  name = var.vs.se_group_ref
}

resource "avi_virtualservice" "https_vs" {
  name = var.vs.name
  pool_ref = avi_pool.lbpool.id
  cloud_ref = data.avi_cloud.default_cloud.id
  tenant_ref = data.avi_tenant.tenant.id
  ssl_key_and_certificate_refs = [data.avi_sslkeyandcertificate.ssl_cert1.id]
  ssl_profile_ref = data.avi_sslprofile.ssl_profile1.id
  application_profile_ref = data.avi_applicationprofile.application_profile1.id
  network_profile_ref = data.avi_networkprofile.network_profile1.id
  vsvip_ref= data.avi_vsvip.vsvip.id
  se_group_ref= data.avi_serviceenginegroup.seg.id
  services {
    port           = var.vs.port
    enable_ssl     = var.vs.ssl
  }
  analytics_policy {
    client_insights = "NO_INSIGHTS"
    all_headers = "true"
    udf_log_throttle = "10"
    significant_log_throttle = "0"
    metrics_realtime_update {
      enabled  = "true"
      duration = "0"
    }
    full_client_logs {
      enabled = "true"
      throttle = "10"
      duration = "0"
    }
  }
}
