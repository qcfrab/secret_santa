import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages"]
  static values = { role: String }

  connect() {
    this.updateBubbles()
    this.scrollToBottom()
    this.observeMessages()
  }

  updateBubbles() {
    const isSanta = this.roleValue === "santa"
    this.element.querySelectorAll(".chat-bubble").forEach(bubble => {
      const fromSanta = bubble.dataset.fromSanta === "true"
      const mine = isSanta ? fromSanta : !fromSanta
      if (mine) {
        bubble.classList.add("mine")
      } else {
        bubble.classList.remove("mine")
      }
    })
  }

  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }

  observeMessages() {
    if (!this.hasMessagesTarget) return

    this.observer = new MutationObserver(() => {
      this.updateBubbles()
      this.scrollToBottom()
    })
    this.observer.observe(this.messagesTarget, { childList: true })
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  submit(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      event.target.closest("form").requestSubmit()
    }
  }
}
