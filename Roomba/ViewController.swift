import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var prefersStatusBarHidden: Bool { return true }

    @IBAction func spiralButtonPressed(_ sender: UIButton) { roombaView.spiralButtonPressed() }
    @IBAction func squareButtonPressed(_ sender: UIButton) { roombaView.squareButtonPressed() }
    @IBAction func startPressed(_ sender: UIButton) { roombaView.start() }
    @IBAction func resetPressed(_ sender:UIButton) { roombaView.reset() }
    @IBAction func addRoomPressed(_ sender:UIButton) { roombaView.addRoomPressed() }
}

