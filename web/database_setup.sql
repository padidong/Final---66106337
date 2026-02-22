-- Table 1: polling_station
CREATE TABLE IF NOT EXISTS polling_station (
    station_id INTEGER PRIMARY KEY,
    station_name TEXT,
    zone TEXT,
    province TEXT
);

-- Insert seed data for polling_station
INSERT INTO polling_station (station_id, station_name, zone, province) VALUES 
(101, 'โรงเรียนวัดพระมหาธาตุ', 'เขต 1', 'นครศรีธรรมราช'),
(102, 'เต็นท์หน้าตลาดท่าวัง', 'เขต 1', 'นครศรีธรรมราช'),
(103, 'ศาลากลางหมู่บ้านคีรีวง', 'เขต 2', 'นครศรีธรรมราช'),
(104, 'หอประชุมอำเภอทุ่งสง', 'เขต 3', 'นครศรีธรรมราช');

-- Table 2: violation_type
CREATE TABLE IF NOT EXISTS violation_type (
    type_id INTEGER PRIMARY KEY,
    type_name TEXT,
    severity TEXT
);

-- Insert seed data for violation_type
INSERT INTO violation_type (type_id, type_name, severity) VALUES 
(1, 'ซื้อสิทธิ์ขายเสียง (Buying Votes)', 'High'),
(2, 'ขนคนไปลงคะแนน (Transportation)', 'High'),
(3, 'หาเสียงเกินเวลา (Overtime Campaign)', 'Medium'),
(4, 'ทำลายป้ายหาเสียง (Vandalism)', 'Low'),
(5, 'เจ้าหน้าที่วางตัวไม่เป็นกลาง (Bias Official)', 'High');

-- Table 3: incident_report
CREATE TABLE IF NOT EXISTS incident_report (
    report_id INTEGER PRIMARY KEY AUTOINCREMENT,
    station_id INTEGER,
    type_id INTEGER,
    reporter_name TEXT,
    description TEXT,
    evidence_photo TEXT,
    timestamp TEXT,
    ai_result TEXT,
    ai_confidence REAL,
    FOREIGN KEY(station_id) REFERENCES polling_station(station_id),
    FOREIGN KEY(type_id) REFERENCES violation_type(type_id)
);

-- Insert seed data for incident_report
INSERT INTO incident_report (station_id, type_id, reporter_name, description, evidence_photo, timestamp, ai_result, ai_confidence) VALUES 
(101, 1, 'พลเมืองดี 01', 'พบเห็นการแจกเงินบริเวณหน้าหน่วย', NULL, '2026-02-08 09:30:00', 'Money', 0.95),
(102, 3, 'สมชาย ใจกล้า', 'มีการเปิดรถแห่เสียงดังรบกวน', NULL, '2026-02-08 10:15:00', 'Crowd', 0.75),
(103, 5, 'Anonymous', 'เจ้าหน้าที่พูดจาชี้นำผู้ลงคะแนน', NULL, '2026-02-08 11:00:00', NULL, 0.0);
