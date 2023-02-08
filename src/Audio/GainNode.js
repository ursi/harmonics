export const create_ = ac => () => {
	const gainNode = ac.createGain()
	return gainNode
}

export const connect = ac => gn => () => gn.connect(ac.destination)
export const setGain = gain => gainNode => () => gainNode.gain.value = gain
