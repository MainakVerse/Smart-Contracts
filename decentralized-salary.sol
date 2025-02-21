// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DecentralizedSalaryPayment {
    address public owner;
    
    struct Employee {
        uint256 salary;
        uint256 nextPayTime;
        bool exists;
    }
    
    mapping(address => Employee) public employees;
    mapping(address => bool) public employers;

    uint256 public payInterval = 30 days; // Monthly payment cycle

    event EmployeeAdded(address indexed employee, uint256 salary);
    event SalaryUpdated(address indexed employee, uint256 newSalary);
    event EmployeeRemoved(address indexed employee);
    event SalaryPaid(address indexed employee, uint256 amount, uint256 timestamp);
    event FundsDeposited(address indexed employer, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier onlyEmployer() {
        require(employers[msg.sender], "Not an authorized employer");
        _;
    }

    modifier employeeExists(address _employee) {
        require(employees[_employee].exists, "Employee not found");
        _;
    }

    constructor() {
        owner = msg.sender;
        employers[msg.sender] = true; // Contract creator is the first employer
    }

    function addEmployer(address _employer) external onlyOwner {
        employers[_employer] = true;
    }

    function removeEmployer(address _employer) external onlyOwner {
        employers[_employer] = false;
    }

    function addEmployee(address _employee, uint256 _salary) external onlyEmployer {
        require(!employees[_employee].exists, "Employee already exists");
        require(_salary > 0, "Salary must be greater than zero");

        employees[_employee] = Employee({
            salary: _salary,
            nextPayTime: block.timestamp + payInterval,
            exists: true
        });

        emit EmployeeAdded(_employee, _salary);
    }

    function updateSalary(address _employee, uint256 _newSalary) external onlyEmployer employeeExists(_employee) {
        require(_newSalary > 0, "Salary must be greater than zero");
        employees[_employee].salary = _newSalary;

        emit SalaryUpdated(_employee, _newSalary);
    }

    function removeEmployee(address _employee) external onlyEmployer employeeExists(_employee) {
        delete employees[_employee];

        emit EmployeeRemoved(_employee);
    }

    function depositFunds() external payable onlyEmployer {
        require(msg.value > 0, "Deposit must be greater than zero");

        emit FundsDeposited(msg.sender, msg.value);
    }

    function paySalary(address _employee) external employeeExists(_employee) {
        Employee storage employee = employees[_employee];
        require(block.timestamp >= employee.nextPayTime, "Salary not due yet");
        require(address(this).balance >= employee.salary, "Insufficient contract balance");

        employee.nextPayTime = block.timestamp + payInterval;
        payable(_employee).transfer(employee.salary);

        emit SalaryPaid(_employee, employee.salary, block.timestamp);
    }

    function getEmployeeDetails(address _employee) external view employeeExists(_employee) returns (uint256 salary, uint256 nextPayTime) {
        Employee storage employee = employees[_employee];
        return (employee.salary, employee.nextPayTime);
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdrawFunds(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "Not enough funds");
        payable(owner).transfer(_amount);
    }
}
