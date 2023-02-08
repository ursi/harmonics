export const defineImpl = nullToMaybe => props => thing => () => {
	customElements.define(props.name, class extends HTMLElement {
		constructor() {
			super()
			this.attachShadow({ mode: "open" })
			const div = document.createElement("div")
			this.shadowRoot.append(div)
			thing(this)(div)()
		}

		static observedAttributes = props.observedAttributes

		attributeChangedCallback(attr, old, new_, ns) {
			props.attributeChangedCallback({
				attr,
				old: nullToMaybe(old),
				new: new_,
				namespace: nullToMaybe(ns),
			})()
		}
	})
}
