import UIKit

var roombaView:RoombaView!
var context : CGContext?

let PI2 = Float.pi * 2
let NONE = -1
var addRoomFlag = false
var startFlag = false
let radius:CGFloat = 30
let wh:CGFloat = 20
let floorColor = UIColor(red:0.25, green:0.25, blue:0.45, alpha:1)
let wallColor = UIColor(red:0.45, green:0.45, blue:0.45, alpha:1)

// MARK:-

struct Room {
    var corner = Array(repeating:CGPoint(), count:2)    // UL,LR
    
    init(_ pt:CGPoint) {
        corner[0] = pt
        corner[1] = pt.offset(10,10)
    }
    
    func l() -> CGFloat { return corner[0].x }
    func r() -> CGFloat { return corner[1].x }
    func t() -> CGFloat { return corner[0].y }
    func b() -> CGFloat { return corner[1].y }
    
    func rect() -> CGRect {
        var ans = CGRect()
        ans.origin = corner[0]
        ans.size.width = r() - l()
        ans.size.height = b() - t()
        return ans
    }
    
    func rightWall() -> CGRect {
        var ans = CGRect()
        ans.origin.x = r() - wh
        ans.origin.y = t()
        ans.size.width = wh
        ans.size.height = b() - t()
        return ans
    }
    
    func topWall() -> CGRect {
        var ans = CGRect()
        ans.origin = corner[0]
        ans.size.width = r() - l()
        ans.size.height = wh
        return ans
    }
    
    func draw() {
        context?.setLineCap(CGLineCap.square)
        
        floorColor.set()
        UIBezierPath(rect:rect()).fill()
        wallColor.set()
        UIBezierPath(rect:rightWall()).fill()
        UIBezierPath(rect:topWall()).fill()
        
        UIColor.black.set()
        context?.setLineWidth(2)
        let y1 = t() + wh
        let x2 = r() - wh
        drawHLine(l(),x2,y1)
        drawVLine(x2,y1,b())
        drawLine(x2,y1,r(),t())
        
        // edge
        UIColor.white.set()
        context?.setLineWidth(5)
        drawHLine(l(),r(),t())
        drawHLine(l(),r(),b())
        drawVLine(l(),t(),b())
        drawVLine(r(),t(),b())
    }
    
    func contains(_ pt:CGPoint) -> Bool {
        if pt.x < l() || pt.x > r() { return false }
        if pt.y < t() || pt.y > b() { return false }
        return true
    }
    
    func distance(_ pt:CGPoint, _ ci:Int) -> Float {
        switch(ci) {
        case 0 : return hypotf(Float(pt.x - l()), Float(pt.y - t()))  // UL
        case 1 : return hypotf(Float(pt.x - r()), Float(pt.y - t()))  // UR
        case 2 : return hypotf(Float(pt.x - r()), Float(pt.y - b()))  // LR
        case 3 : return hypotf(Float(pt.x - l()), Float(pt.y - b()))  // LL
        default : return Float(9999)
        }
    }
    
    mutating func orientCorners() {
        corner[0] = grid(corner[0])
        corner[1] = grid(corner[1])
        
        if l() > r() { let t = corner[0].x; corner[0].x = corner[1].x; corner[1].x = t }
        if t() > b() { let t = corner[0].y; corner[0].y = corner[1].y; corner[1].y = t }
    }
    
    mutating func cornerMoved(_ pt:CGPoint) {
        if fabs(pt.x - l()) < fabs(pt.x - r()) { corner[0].x = pt.x } else { corner[1].x = pt.x }
        if fabs(pt.y - t()) < fabs(pt.y - b()) { corner[0].y = pt.y } else { corner[1].y = pt.y }
        orientCorners()
    }
}

class Rooms {
    var room:[Room] = []
    var rIndex = NONE   // which room
    var cIndex = NONE   // which corner
    
    init() { reset() }
    
    func reset() {
        rIndex = NONE
        room.removeAll()
    }
    
    func isInside(_ pt:CGPoint) -> Bool {
        for r in room { if r.contains(pt) { return true } }
        return false
    }
    
    func addRoom(_ pt:CGPoint) {
        room.append(Room(pt))
        rIndex = room.count - 1
    }
    
    func findClosestCorner(_ pt:CGPoint) {
        rIndex = NONE
        var bestdistance:Float = 9999
        
        func checkDistance(_ ri:Int, _ ci:Int) {
            let dist = room[ri].distance(pt,ci)
            if dist < bestdistance {
                bestdistance = dist
                rIndex = ri
                cIndex = ci
            }
        }
        
        for r in 0 ..< room.count {
            for c in 0 ..< 4 {
                checkDistance(r,c)
            }
        }
    }
    
    func cornerMoved(_ pt:CGPoint) { room[rIndex].cornerMoved(pt) }
    
    func draw() {
        var r = CGRect()
        
        if room.count == 0 { return }
        for rm in rooms.room { rm.draw() }
        
        func overlapBot(_ top:Room, _ bot:Room) {
            let x1 = max(top.l(),bot.l())
            let x2 = min(top.r(),bot.r())
            if x1 >= x2 { return }
           
            r.origin.x = x1 + 3
            r.origin.y = top.b() - 3
            r.size.width = x2 - x1 - wh - 4
            r.size.height = wh + 5

            floorColor.set()
            UIBezierPath(rect:r).fill()
            
            if top.r() <= bot.r() {     // LL
                r.origin.x = top.r() - wh + 1
                r.origin.y = top.b() - 3
                r.size.width = wh - 4
                r.size.height = wh + 3

                wallColor.set()
                UIBezierPath(rect:r).fill()
                
                UIColor.black.set()
                context?.setLineWidth(2)
                drawVLine(r.origin.x-1,r.origin.y-2,r.origin.y+wh+2)
                
                if top.r() < bot.r() {
                    let x1 = r.origin.x-1
                    let y1 = r.origin.y+wh+3
                    let x2 = x1 + wh - 3
                    let y2 = y1 - wh + 3
                    drawHLine(x1,x2,y1)
                    drawLine(x1,y1,x2,y2)
                }
            }
            
            if top.r() > bot.r() {      // UL
                let xOffset:CGFloat = -wh + 9
                let yOffset:CGFloat = -5

                floorColor.set()
                context?.setLineWidth(wh)
                drawLine(x2-wh+xOffset,top.b()+wh+yOffset,x2+xOffset+1,top.b()+yOffset)
            }
            
            if top.l() > bot.l() {      // UL
                let x1 = top.l() - 2
                let y1 = top.b() + wh + 5
                let x2 = x1 + wh
                let y2 = y1 - wh
                let lx1 = top.l() - 13
                let ly1 = top.b() + wh
                let lx2 = lx1 + wh - 3
                let ly2 = ly1 - wh + 3
                
                floorColor.set()
                context?.setLineWidth(wh)
                drawLine(x1,y1,x2,y2)
                
                UIColor.black.set()
                context?.setLineWidth(2)
                drawLine(lx1,ly1,lx2,ly2)
            }
        }
        
        func overlapRht(_ lft:Room, _ rht:Room) {
            let y1 = max(lft.t(),rht.t())
            let y2 = min(lft.b(),rht.b())
            if y1 >= y2 { return }
            
            r.origin.x = lft.r() - wh - 2
            r.origin.y = y1 + 3
            r.size.width = wh + 5
            r.size.height = y2 - y1 - 6
            floorColor.set()
            UIBezierPath(rect:r).fill()
            
            if lft.t() < rht.t() {      // UR
                r.origin.x = lft.r() - wh + 1
                r.origin.y = rht.t() - 3
                r.size.width = wh - 4
                r.size.height = wh + 2

                wallColor.set()
                UIBezierPath(rect:r).fill()
                
                r.origin.x += wh - 4
                r.origin.y += 5
                r.size.width = 10
                r.size.height = wh - 3
                UIBezierPath(rect:r).fill()

                let x1 = lft.r() - wh
                let x2 = x1 + wh + 2
                let y1 = rht.t() - 3
                let y2 = y1 + wh + 3

                UIColor.black.set()
                context?.setLineWidth(2)
                drawVLine(x1,y1,y2)
                drawHLine(x1,x2+10,y2)
                drawLine(x1,y2,x2-5,y1+5)
            }
            
            if lft.t() == rht.t() {
                let x1 = lft.r() - wh - 5
                let y1 = rht.t() + 2
                
                r.origin.x = x1
                r.origin.y = y1
                r.size.width = wh + 10
                r.size.height = wh - 2
                wallColor.set()
                UIBezierPath(rect:r).fill()
                
                UIColor.black.set()
                context?.setLineWidth(2)
                drawHLine(x1,x1 + wh + 10,y1 + wh - 2)
            }
            
            if lft.t() > rht.t() {
                let x1 = lft.r() - wh - 5
                let y1 = lft.t() + 2
                let x2 = x1 + wh + 1
                let y2 = y1 + wh
                let x3 = x2 - 10
                let y3 = y2 - 2

                r.origin.x = x1
                r.origin.y = y1
                r.size.width = wh + 10
                r.size.height = wh - 2
                wallColor.set()
                UIBezierPath(rect:r).fill()
                
                floorColor.set()
                context?.setLineWidth(wh)
                drawLine(x2,y2,x2+wh,y2-wh)

                UIColor.black.set()
                context?.setLineWidth(2)
                drawHLine(x3-10,x3,y3)
                drawLine(x3,y3,x3+wh,y3-wh)
            }

            if lft.b() > rht.b() {
                let x1 = lft.r() - wh - 5
                let y1 = rht.b() + 4
                let x2 = x1 + wh
                let y2 = y1 - wh
                let x3 = x1 + 5
                let y3 = y1 + 10
                
                floorColor.set()
                context?.setLineWidth(wh)
                drawLine(x1,y1,x2,y2)
                
                UIColor.black.set()
                context?.setLineWidth(2)
                drawLine(x3,y3,x3+wh-3,y3-wh+3)
            }
        }
        
        // overlap
        for i in 0 ..< room.count - 1 {
            for j in i+1 ..< room.count {
                if room[i].b() == room[j].t() { overlapBot(room[i],room[j]) }
                if room[i].t() == room[j].b() { overlapBot(room[j],room[i]) }
                if room[i].r() == room[j].l() { overlapRht(room[i],room[j]) }
                if room[i].l() == room[j].r() { overlapRht(room[j],room[i]) }
            }
        }
    }
}

// MARK:-

class CircularBuffer {
    var max:Int = 0
    var head = 0
    var tail = 0
    var data:[CGPoint]
    
    init(_ count:Int) {
        max = count
        data = Array(repeating:CGPoint(), count:max + 1)
    }
    
    func reset() {
        head = 0
        tail = 0
        for i in 0 ..< max+1 { data[i].x = 0; data[i].y = 0 }
    }
    
    func isEmpty() -> Bool { return head == tail }
    
    func last() -> CGPoint {
        var index = head - 1
        if index < 0 { index = max }
        return data[index]
    }
    
    func add(_ pt:CGPoint) {
        data[head] = pt
        head += 1
        if head > max { head = 0}
        if head == tail {
            tail += 1
            if tail > max { tail = 0}
        }
    }
    
    func draw() {
        func decrement(_ v:Int) -> Int {
            var ans = v - 1
            if ans < 0 { ans = max }
            return ans
        }
        
        if isEmpty() { return }
        
        var i1 = decrement(head)
        var i2 = decrement(i1)
        
        UIColor(red:1, green:1, blue:1, alpha: 0.1).set()
        context?.setLineWidth(radius * 2)
        context?.setLineCap(CGLineCap.round)
        
        while true {
            drawLine(data[i1],data[i2])
            
            i1 = decrement(i1)
            if i1 == tail { break }
            
            i2 = decrement(i2)
        }
    }
}

// MARK:-

let STATE_MOVING = 0
let STATE_ROTATING = 1
let STATE_SPIRAL = 2
let STATE_SQUARE = 3

var rooms = Rooms()
var roomba = Roomba()

class Roomba {
    var offsets:[CGPoint] = []
    var pos = CGPoint()
    var path = CircularBuffer(500)
    var running = false
    var dx:CGFloat = 0
    var dy:CGFloat = 0
    var newAngle:Float = 0
    var currentAngle:Float = 0
    var deltaAngle:Float = 0
    var spiralAngle:Float = 0
    var spiralDeltaRatio:Float = 0
    var squareDistance:Float = 0
    var squareOldPos = CGPoint()
    var state = STATE_ROTATING
    var squareState = STATE_MOVING
    
    init() {
        var newAngle:Float = 0
        offsets.removeAll()
        for _ in 0 ..< 8 {
            offsets.append(CGPoint(x: CGFloat(sinf(newAngle)) * radius, y: CGFloat(cosf(newAngle)) * radius))
            newAngle += Float.pi / 4
        }
        
        reset()
    }
    
    func reset() {
        currentAngle = 0
        path.reset()
        running = false
    }
    
    let squareHop:Float = 22
    
    func newState(_ s:Int) {
        state = s
        
        if state == STATE_SPIRAL {
            spiralAngle = 0.6 //0.8
            spiralDeltaRatio = 0.98 // 0.979 //0.98
        }
        
        if state == STATE_SQUARE {
            squareDistance = squareHop
            squareTurn()
        }
    }
    
    func squareTurn() {
        squareState = STATE_ROTATING
        squareDistance += squareHop
        squareOldPos = pos
        newAngle.clampRadian(newAngle +  Float.pi / 2)
    }
    
    func rotateToNewAngle() -> Bool {
        deltaAngle = newAngle - currentAngle
        if deltaAngle > 0.4 { deltaAngle = 0.4 } else if deltaAngle < -0.4 { deltaAngle = -0.4 }
        
        currentAngle.clampRadian(currentAngle + deltaAngle)
        
        if fabs(newAngle - currentAngle) < 0.6 {
            currentAngle = newAngle
            dx = CGFloat(sinf(currentAngle) * 20)
            dy = CGFloat(cosf(currentAngle) * 20)
            return true
        }
        
        return false
    }
    
    func moveInCurrentDirection() {
        if state == STATE_MOVING && percentChance(2) {
            newState(STATE_SPIRAL)
            return
        }
        
        if state == STATE_MOVING && percentChance(2) {
            newState(STATE_SQUARE)
            return
        }
        
        let npos = pos.offset(dx,dy)
        
        if legalPosition(npos) {
            path.add(npos)
            pos = npos
        }
        else {
            newAngle = fRandom(0,Float.pi * 2)
            newState(STATE_ROTATING)
        }
    }
    
    func update() {
        if !running { return }
        
        if state == STATE_SQUARE {
            if squareState == STATE_ROTATING {
                if rotateToNewAngle() {
                    squareState = STATE_MOVING
                }
            }
            
            if squareState == STATE_MOVING {
                moveInCurrentDirection()
                if state != STATE_SQUARE { return } // hit wall.
                
                let d = hypotf(Float(pos.x - squareOldPos.x), Float(pos.y - squareOldPos.y))
                if d >= squareDistance {
                    squareTurn()
                }
            }
            
            return
        }
        
        if state == STATE_SPIRAL {
            currentAngle.clampRadian(currentAngle + spiralAngle)
            dx = CGFloat(sinf(currentAngle) * 20)
            dy = CGFloat(cosf(currentAngle) * 20)
            
            spiralAngle *= spiralDeltaRatio
            spiralDeltaRatio *= 1.00011
            if fabs(spiralAngle) < 0.01 { state = STATE_MOVING; return }
            if spiralDeltaRatio > 1 { state = STATE_MOVING; return }
            
            moveInCurrentDirection()
            return
        }
        
        if state == STATE_MOVING {
            moveInCurrentDirection()
            return
        }
        
        if rotateToNewAngle() {
            newState(STATE_MOVING)
        }
    }
    
    func start(_ pt:CGPoint) {
        pos = pt
        path.add(pt)
        path.add(pt)
        running = true
        newState(STATE_ROTATING)
    }
    
    func legalPosition(_ pt:CGPoint) -> Bool {
        for i in 0 ..< 8 {
            var p = pt
            p.offset(offsets[i])
            if !rooms.isInside(p) { return false }
        }
        
        return true
    }
    
    func draw() {
        if path.isEmpty() { return }
        
        path.draw()
        
        // roomba -------------------------------
        let pt = path.last()
        let dia = radius * 2
        
        UIColor.gray.set()
        context?.beginPath()
        context?.addEllipse(in: CGRect(x:pt.x - radius, y:pt.y-radius, width:dia, height:dia))
        context?.fillPath()
        
        UIColor.darkGray.set()
        context?.setLineWidth(8)
        context?.beginPath()
        context?.addEllipse(in: CGRect(x:pt.x - radius, y:pt.y-radius, width:dia, height:dia))
        context?.strokePath()

        UIColor.black.set()
        context?.setLineWidth(2)
        context?.beginPath()
        context?.addEllipse(in: CGRect(x:pt.x - radius, y:pt.y-radius, width:dia, height:dia))
        context?.strokePath()

        // top ------------------------------------
        let a1 = currentAngle - 0.4
        let a2 = currentAngle + 0.4
        let r2 = radius * 3 / 4
        var ss = CGFloat(sinf(a1))
        var cc = CGFloat(cosf(a1))
        let p1 = CGPoint(x:pos.x + ss * radius, y:pos.y + cc * radius)
        let p2 = CGPoint(x:pos.x + ss * r2, y:pos.y + cc * r2)
        ss = CGFloat(sinf(a2))
        cc = CGFloat(cosf(a2))
        let p3 = CGPoint(x:pos.x + ss * r2, y:pos.y + cc * r2)
        let p4 = CGPoint(x:pos.x + ss * radius, y:pos.y + cc * radius)
        
        context?.setLineWidth(3)
        context?.beginPath()
        context?.move(to: p1)
        context?.addLine(to: p2)
        context?.addLine(to: p3)
        context?.addLine(to: p4)
        context?.strokePath()
        
        // light ------------------------------------
        let LSZ:CGFloat = 12
        switch state {
        case STATE_MOVING : UIColor.green.set()
        case STATE_ROTATING : UIColor.yellow.set()
        case STATE_SPIRAL : UIColor.blue.set()
        case STATE_SQUARE : UIColor.black.set()
        default : UIColor.yellow.set()
        }
        context?.beginPath()
        context?.addEllipse(in: CGRect(x:pt.x - LSZ, y:pt.y - LSZ, width:LSZ*2, height:LSZ*2))
        context?.fillPath()
        
    }
}

// MARK:-

class RoombaView: UIView
{
    var timer = Timer()
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        roombaView = self
        reset()
        timer = Timer.scheduledTimer(timeInterval: 1.0/20.0, target:self, selector: #selector(timerHandler), userInfo: nil, repeats:true)
    }
    
    @objc func timerHandler() {
        if roomba.running {
            roomba.update()
            setNeedsDisplay()
        }
    }
    
    func reset() {
        rooms.reset()
        roomba.reset()
        setNeedsDisplay()
    }
    
    func addRoomPressed() {  addRoomFlag = true; setNeedsDisplay() }
    
    func spiralButtonPressed() { roomba.newState(STATE_SPIRAL) }
    func squareButtonPressed() { roomba.newState(STATE_SQUARE) }
    
    func start() {
        roomba.reset()
        startFlag = true
        setNeedsDisplay()
    }
    
    // MARK: Draw --------------------------
    
    override func draw(_ rect: CGRect) {
        context = UIGraphicsGetCurrentContext()
        
        let color = addRoomFlag ? UIColor(red:0.2, green:0, blue:0, alpha: 1) : UIColor.black
        color.setFill()
        UIBezierPath(rect:rect).fill()
        
        rooms.draw()
        roomba.draw()
    }
    
    // MARK: Touch --------------------------
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let pt = grid(touch.location(in: self))
            
            if startFlag {
                roomba.start(pt)
                setNeedsDisplay()
                return
            }
            
            if addRoomFlag {
                rooms.addRoom(pt)
            }
            else {
                rooms.findClosestCorner(pt)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if rooms.rIndex == NONE { return }
        if startFlag { return }
        
        for touch in touches {
            let pt = grid(touch.location(in: self))
            rooms.cornerMoved(pt)
            setNeedsDisplay()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if addRoomFlag {
            addRoomFlag = false
            setNeedsDisplay()
        }
        
        startFlag = false
    }
}

// MARK:-

func min(_ v1:CGFloat, _ v2:CGFloat) -> CGFloat { if v1 < v2 { return v1 }; return v2 }
func max(_ v1:CGFloat, _ v2:CGFloat) -> CGFloat { if v1 > v2 { return v1 }; return v2 }

func drawLine(_ p1:CGPoint, _ p2:CGPoint) {
    context?.beginPath()
    context?.move(to:p1)
    context?.addLine(to:p2)
    context?.strokePath()
}

func drawLine(_ x1:CGFloat, _ y1:CGFloat, _ x2:CGFloat, _ y2:CGFloat) { drawLine(CGPoint(x:x1, y:y1),CGPoint(x: x2, y:y2)) }
func drawHLine(_ x1:CGFloat, _ x2:CGFloat, _ y:CGFloat) { drawLine(CGPoint(x:x1, y:y),CGPoint(x: x2, y:y)) }
func drawVLine(_ x:CGFloat, _ y1:CGFloat, _ y2:CGFloat) { drawLine(CGPoint(x:x,y:y1),CGPoint(x:x,y:y2)) }

func grid(_ pt:CGPoint) -> CGPoint {
    var ans = pt
    let GRID = 30
    ans.x = CGFloat( (Int(pt.x + CGFloat(GRID) / 2) / GRID ) * GRID )
    ans.y = CGFloat( (Int(pt.y + CGFloat(GRID) / 2) / GRID ) * GRID )
    return ans
}

func fRandom(_ vmin:Float, _ vmax:Float) -> Float {
    let ratio = Float(arc4random() & 1023) / Float(1024)
    return vmin + (vmax - vmin) * ratio
}

func percentChance(_ percent:Int) -> Bool {
    return fRandom(0,500) <= Float(percent)
}

extension CGPoint {
    mutating func random(_ dist:Float) {
        x += CGFloat(-dist/2.0 + fRandom(0,dist))
        y += CGFloat(-dist/2.0 + fRandom(0,dist))
    }
    
    mutating func ratio(_ p1:CGPoint, _ p2:CGPoint, _ ratio:Float) {
        x = CGFloat(Float(p1.x) + Float(p2.x - p1.x) * ratio)
        y = CGFloat(Float(p1.y) + Float(p2.y - p1.y) * ratio)
    }
    
    mutating func angledOffset(_ newAngle:Float, _ dist:Float) {
        x += CGFloat(cosf(newAngle) * dist)
        y += CGFloat(sinf(newAngle) * dist)
    }
    
    mutating func offset(_ amt:CGPoint) {
        x += amt.x
        y += amt.y
    }
    
    func offset(_ dx:CGFloat,_ dy:CGFloat) -> CGPoint {
        var ans = self
        ans.x += dx
        ans.y += dy
        return ans
    }
}

extension Float {
    mutating func clampRadian(_ v:Float) {
        var v = v
        if v < 0 { v += PI2 } else if v >= PI2 { v -= PI2 }
        self = v
    }
}


