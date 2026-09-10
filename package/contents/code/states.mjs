const ACTIVE_STATES = Object.freeze({
  camera: ["recording", "streaming"],
  climate: ["auto", "dry", "cool", "heat", "heat_cool", "fan"],
  water_heater: ["eco", "electric", "gas", "heat_pump", "high_demand", "performance"],
  cover: ["open", "opening", "closing"],
  valve: ["open", "opening", "closing"],
  lock: ["unlocked", "jammed"],
  alarm_control_panel: ["armed_home", "armed_away", "armed_night", "armed_vacation", "armed_custom_bypass", "triggered"],
  media_player: ["idle", "playing", "paused", "buffering"],
  vacuum: ["cleaning", "returning", "paused"],
  timer: ["active", "paused"]
})

export function isActiveState(domain, state) {
  if (state === "on") return true
  return ACTIVE_STATES[domain]?.includes(state) ?? false
}