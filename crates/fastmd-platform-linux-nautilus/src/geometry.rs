/// A screen-space point.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct ScreenPoint {
    /// Horizontal coordinate in desktop space.
    pub x: f64,
    /// Vertical coordinate in desktop space.
    pub y: f64,
}

/// A screen-space rectangle.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct ScreenRect {
    /// Left edge.
    pub x: f64,
    /// Top edge.
    pub y: f64,
    /// Width in screen-space units.
    pub width: f64,
    /// Height in screen-space units.
    pub height: f64,
}

impl ScreenRect {
    /// Returns true when the point lies inside the rectangle.
    pub fn contains(self, point: ScreenPoint) -> bool {
        point.x >= self.x
            && point.x <= self.x + self.width
            && point.y >= self.y
            && point.y <= self.y + self.height
    }

    fn center(self) -> ScreenPoint {
        ScreenPoint {
            x: self.x + self.width / 2.0,
            y: self.y + self.height / 2.0,
        }
    }
}

/// One desktop monitor.
#[derive(Debug, Clone, PartialEq)]
pub struct Monitor {
    /// Stable monitor identifier if the backend can provide one.
    pub id: String,
    /// Full monitor frame.
    pub frame: ScreenRect,
    /// Usable work area after taskbars, docks, and shell chrome.
    pub work_area: ScreenRect,
    /// Whether the monitor is the primary display.
    pub primary: bool,
}

/// The monitor layout visible to the current session.
#[derive(Debug, Clone, PartialEq)]
pub struct MonitorLayout {
    /// Known monitors.
    pub monitors: Vec<Monitor>,
}

impl MonitorLayout {
    /// Returns the containing monitor when possible, otherwise the nearest one.
    pub fn monitor_for_point(&self, point: ScreenPoint) -> Option<&Monitor> {
        if let Some(containing) = self
            .monitors
            .iter()
            .find(|monitor| monitor.work_area.contains(point))
        {
            return Some(containing);
        }

        self.monitors.iter().min_by(|left, right| {
            let left_distance = squared_distance(point, left.work_area.center());
            let right_distance = squared_distance(point, right.work_area.center());
            left_distance
                .partial_cmp(&right_distance)
                .unwrap_or(std::cmp::Ordering::Equal)
                .then_with(|| right.primary.cmp(&left.primary))
                .then_with(|| left.id.cmp(&right.id))
        })
    }
}

fn squared_distance(a: ScreenPoint, b: ScreenPoint) -> f64 {
    let dx = a.x - b.x;
    let dy = a.y - b.y;
    dx * dx + dy * dy
}
