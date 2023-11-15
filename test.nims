const nims = try: gorgeEx("echo").exitCode.bool except: false
when nims:
  when defined(debug):
    {.warning: "Tried to add a nimscript only module into a binary app.".}
  else:
    {.error: "Tried to add a nimscript only module into a binary app.".}