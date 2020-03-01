ruleset com.blacklite.krl.twilio.key {
  meta {
    name "Twilio Key Module"
    key twilioKeys {
      "account_sid" : "<<ACCOUNT SID HERE>>",
      "auth_token" : "<<TOKEN HERE>>"
    }

    provide keys twilioKeys to com.blacklite.krl.twilio
  }
}
