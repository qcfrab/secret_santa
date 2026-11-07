import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  open() {
    if (this.hasDialogTarget) {
      if (typeof this.dialogTarget.showModal === "function") {
        this.dialogTarget.showModal()
      } else {
        this.dialogTarget.setAttribute("open", "")
      }
    }
  }

  close() {
    if (this.hasDialogTarget) {
      if (typeof this.dialogTarget.close === "function") {
        this.dialogTarget.close()
      } else {
        this.dialogTarget.removeAttribute("open")
      }
    }
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) {
      this.close()
    }
  }
}
