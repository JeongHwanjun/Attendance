// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Attendance {
    event AttendanceMarked(address indexed student, uint256 lectureId, uint256 timestamp);

    struct AttendanceInfo {
        uint256 timestamp;
        //bool isValid; // 정답을 맞췄는지 여부
        string extraInfo; // 비고 - 필요시 추가정보 저장
    }

    // lectureId => student => AttendanceInfo
    mapping(uint256 => mapping(address => AttendanceInfo[])) public attendances;

    // 검증 과정을 생략하고 기록에 집중 => 가스비 절약, 업데이트 불필요
    function markAttendance(uint256 lectureId, string memory extraInfo) external {
        attendances[lectureId][msg.sender].push(AttendanceInfo(block.timestamp, extraInfo));
        emit AttendanceMarked(msg.sender, lectureId, block.timestamp);
    }

    // 원하는 순서의 출석정보 반환. 하나의 강의에 여러번 출석 가능함.
    function getAttendanceByIndex(uint256 lectureId, address studentId, uint256 index) external view
    returns (uint256 timestamp, string memory extraInfo) {
        AttendanceInfo storage info = attendances[lectureId][studentId][index];
        return (info.timestamp, info.extraInfo);
    }

    // 출석의 길이만 반환
    function getAttendanceLength(uint256 lectureId, address studentId) external view returns (uint256 length) {
        return attendances[lectureId][studentId].length;
    }
}

