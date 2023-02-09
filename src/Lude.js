export const numberToString = n => n.toString()

export const stringToNumberImpl = str => {
	if (str === "") return null
	const n = +str
	if (n.toString() === "NaN") return null
	return n
}
