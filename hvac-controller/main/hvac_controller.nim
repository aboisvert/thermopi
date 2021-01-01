
import
  nesper/consts,
  nesper/general,
  nesper/esp/esp_log,
  nesper/net_utils,
  nesper/nvs_utils,
  nesper/events,
  nesper/wifi,
  nesper/timers,
  std/asyncdispatch,
  server,
  hvac_utils

# Configurable environment, e.g., -d:WIFI_SSID=mySSID
const WIFI_SSID {.strdefine.}: string = "NOSSID"
const WIFI_PASSWORD  {.strdefine.}: string = ""
const WIFI_HOSTNAME  {.strdefine.}: string = "hvac-controller"
const WIFI_PORT      {.intdefine.}: int = 80

const
  GOT_IPV4_BIT* = EventBits_t(BIT(1))
  CONNECTED_BITS* = (GOT_IPV4_BIT)

var connectEventGroup: EventGroupHandle_t

proc ipReceivedHandler*(
  arg: pointer;
  event_base: esp_event_base_t;
  event_id: int32;
  event_data: pointer
) {.cdecl.} =
  var event: ptr ip_event_got_ip_t = cast[ptr ip_event_got_ip_t](event_data)
  logi TAG, "event.ip_info.ip: %s", $(event.ip_info.ip)
  let currentIpAddress = toIpAddress(event.ip_info.ip.address)
  logi TAG, "got event ip: %s", $currentIpAddress
  discard xEventGroupSetBits(connectEventGroup, GOT_IPV4_BIT)

proc onWifiDisconnect*(
  arg: pointer;
  event_base: esp_event_base_t;
  event_id: int32;
  event_data: pointer
) {.cdecl.} =
  logi(TAG, "Wi-Fi disconnected, trying to reconnect...")
  check: esp_wifi_connect()

proc wifiStart*() =
  ##  set up connection, Wi-Fi or Ethernet
  let wcfg: wifi_init_config_t = wifi_init_config_default()
  discard esp_wifi_init(unsafeAddr(wcfg))

  # Register event handlers to stop the server when Wi-Fi or Ethernet is disconnected,
  # and re-start it upon connection.
  WIFI_EVENT_STA_DISCONNECTED.eventRegister(onWifiDisconnect, nil)
  IP_EVENT_STA_GOT_IP.eventRegister(ipReceivedHandler, nil)

  check: esp_wifi_set_storage(WIFI_STORAGE_RAM)

  var wifi_config: wifi_config_t
  wifi_config.sta.ssid.setFromString(WIFI_SSID)
  wifi_config.sta.password.setFromString(WIFI_PASSWORD)

  logi(TAG, "Connecting to %s...", wifi_config.sta.ssid)
  check: esp_wifi_set_mode(WIFI_MODE_STA)
  check: esp_wifi_set_config(ESP_IF_WIFI_STA, addr(wifi_config))
  check: esp_wifi_start()
  check: tcpip_adapter_set_hostname(TCPIP_ADAPTER_IF_STA, WIFI_HOSTNAME)
  check: esp_wifi_connect()

proc wifiStop*() =
  ##  tear down connection, release resources
  WIFI_EVENT_STA_DISCONNECTED.eventUnregister(onWifiDisconnect)
  IP_EVENT_STA_GOT_IP.eventUnregister(ipReceivedHandler)
  check: esp_wifiStop()
  check: esp_wifi_deinit()

proc waitUntilConnected() =
  discard xEventGroupWaitBits(connectEventGroup, CONNECTED_BITS, 1, 1, portMAX_DELAY)

proc connect*(): esp_err_t =
  if connectEventGroup != nil: return ESP_ERR_INVALID_STATE
  connectEventGroup = xEventGroupCreate()
  wifiStart()
  waitUntilConnected()
  logi(TAG, "Connected to %s", WIFI_SSID)
  return ESP_OK

proc disconnect*(): esp_err_t =
  if connectEventGroup == nil: return ESP_ERR_INVALID_STATE
  vEventGroupDelete(connectEventGroup)
  connectEventGroup = nil
  wifiStop()
  logi(TAG, "Disconnected from %s", WIFI_SSID)
  return ESP_OK

proc timerTriggered*(arg: pointer)  {.cdecl.} =
  var server = cast[ptr Server](arg)
  server.updateHvacState()

proc timerSetup(server: ptr Server): esp_err_t =
  logi(TAG, "timer setup\n")
  var timerHandle = createTimer(
    callback = timerTriggered,
    arg = server,
    dispatchMethod = ESP_TIMER_TASK,
    name = "HVAC_TIMEOUT")
  logi(TAG, "start periodic\n")
  esp_timer_start_periodic(timerHandle, ALIVE_TIMEOUT.toMicros.uint64 div 4)

app_main():
  var server: Server
  try:
    initNvs()
    tcpip_adapter_init()
    check: esp_event_loop_create_default()
    logi(TAG, "wifi setup!\n")
    check: connect()
    check: timerSetup(server.addr)
    echo("run_http_server\n")
    addr(server).start(WIFI_PORT)
    runForever()
  except:
    let e = getCurrentException()
    let msg = getCurrentExceptionMsg()
    echo "app_main() exception ", repr(e), " with message ", msg
