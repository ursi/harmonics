export const create = audioContext => () => {
	const oscillator = audioContext.createOscillator()
	return oscillator
}

export const setFreq = freq => osc => () => osc.frequency.value = freq
export const connect = gainNode => osc => () => osc.connect(gainNode)
export const disconnect = osc => () => osc.disconnect()
export const start_ = osc => () => osc.start()
export const stop_ = osc => () => osc.stop()
