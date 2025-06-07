// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Attendance {
    enum UserType { None, Student, Professor, Admin }
    struct User {
        UserType role;
        string name;
    }

    struct Lecture {
        string title;
        address professor;
        uint256 lectureId;
        uint256 createdAt;
        bool active;
    }

    struct AttendanceRecord {
        bool attended;
        uint256 timestamp;
    }
    
    address public owner;
    uint256 public nextLectureId;
    mapping(address => User) public users;
    mapping(uint256 => Lecture) public lectures;
    mapping(uint256 => address[]) public lectureStudents; // 학생 명단
    mapping(uint256 => mapping(address => AttendanceRecord)) public attendanceRecords; // 출석 기록

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    modifier onlyAdmin() {
        require(users[msg.sender].role == UserType.Admin, "Not admin");
        _;
    }
    modifier onlyProfessor() {
        require(users[msg.sender].role == UserType.Professor, "Not professor");
        _;
    }
    modifier onlyStudent() {
        require(users[msg.sender].role == UserType.Student, "Not student");
        _;
    }

    constructor() {
        owner = msg.sender;
        users[msg.sender] = User(UserType.Admin, "admin");
    }

    // 유저 등록 (관리자만)
    function registerUser(address userAddr, UserType role, string memory name) public onlyAdmin {
        require(users[userAddr].role == UserType.None, "Already registered");
        users[userAddr] = User(role, name);
    }

    // 강의 개설 (교수만)
    function createLecture(string memory title) public onlyProfessor returns (uint256) {
        // 기본적으로 비활성 상태로 등록됨
        lectures[nextLectureId] = Lecture(title, msg.sender, nextLectureId, block.timestamp, false);
        nextLectureId++;
        return nextLectureId - 1;
    }

    // 강의 활성화
    function activateLecture(uint256 lectureId) public onlyProfessor {
        // 강의 번호가 유효한지 확인
        require(0 <= lectureId && lectureId < nextLectureId, "Invalid lectureId");
        // 강의의 교수만 활성화 가능
        require(lectures[lectureId].professor == msg.sender, "You can't activate this lecture");
        // 강의가 이미 비활성 상태여야 활성화 가능
        require(!lectures[lectureId].active, "Lecture already active");
        // 활성화
        lectures[lectureId].active = true;
    }

    // 강의 비활성화
    function deactivateLecture(uint256 lectureId) public onlyProfessor {
        // 강의 번호가 유효한지 확인
        require(0 <= lectureId && lectureId < nextLectureId, "Invalid lectureId");
        // 강의의 교수만 비활성화 가능
        require(lectures[lectureId].professor == msg.sender, "You can't deactivate this lecture");
        // 강의가 이미 활성 상태여야 비활성화 가능
        require(lectures[lectureId].active, "Lecture already active");
        lectures[lectureId].active = false;
    }

    // 강의 등록 (학생만)
    function enrollLecture(uint256 lectureId) public onlyStudent {
        require(lectures[lectureId].active, "Lecture not active");
        // 이미 등록된 학생은 중복 등록 불가
        for (uint i = 0; i < lectureStudents[lectureId].length; i++) {
            require(lectureStudents[lectureId][i] != msg.sender, "Already enrolled");
        }
        lectureStudents[lectureId].push(msg.sender);
    }

    // 출석 체크 (학생만, 프론트/백엔드에서 이미 인증 후)
    function markAttendance(uint256 lectureId) public onlyStudent {
        // 강의가 비활성 상태면 거절
        require(lectures[lectureId].active, "Lecture not active");
        // 등록된 학생만 가능
        bool isEnrolled = false;
        for (uint i = 0; i < lectureStudents[lectureId].length; i++) {
            if (lectureStudents[lectureId][i] == msg.sender) {
                isEnrolled = true;
                break;
            }
        }
        require(isEnrolled, "Not enrolled in this lecture");
        // 중복으로 출석할 수 없음
        require(!attendanceRecords[lectureId][msg.sender].attended, "Already attended");
        attendanceRecords[lectureId][msg.sender] = AttendanceRecord(true, block.timestamp);
    }

    // 출석 조회
    function checkAttendance(uint256 lectureId, address student) public view returns (bool, uint256) {
        AttendanceRecord memory att = attendanceRecords[lectureId][student];
        return (att.attended, att.timestamp);
    }
}

