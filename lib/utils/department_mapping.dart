// Department and Course Mapping Utility

class DepartmentMapping {
  // List of all departments/colleges for counselor assignment
  static const List<String> departments = [
    'College of Engineering',
    'College of Maritime Education',
    'College of Hospitality and Tourism Management',
    'College of Nursing',
    'College of Criminology',
    'College of Customs Administration',
    'College of Business and Accountancy',
    'College of Teacher Education',
    'College of Computer Studies',
    'Basic Education Department',
    'Senior High School Department',
    'Volunteer',
  ];

  // List of all college courses/programs
  static const List<String> collegePrograms = [
    // Engineering
    'Bachelor of Science in Computer Engineering',
    'Bachelor of Science in Electrical Engineering',
    'Bachelor of Science in Electronics Engineering',
    'Bachelor of Science in Industrial Engineering',
    'Bachelor of Science in Mechanical Engineering',
    
    // Maritime
    'Bachelor of Science in Marine Engineering',
    'Bachelor of Science in Marine Transportation',
    
    // Hospitality and Tourism
    'Bachelor of Science in Hospitality Management',
    'Bachelor of Science in Tourism Management',
    
    // Nursing
    'Bachelor of Science in Nursing',
    
    // Criminology
    'Bachelor of Science in Criminology',
    'Master of Science in Criminal Justice',
    
    // Customs
    'Bachelor of Science in Customs Administration',
    
    // Business and Accountancy
    'Bachelor of Science in Accountancy',
    'Bachelor of Science in Business Administration',
    'Bachelor of Science in Management Accounting',
    'Bachelor of Science in Real Estate Management',
    
    // Teacher Education
    'Bachelor of Early Childhood Education',
    'Bachelor of Elementary Education',
    'Bachelor of Secondary Education',
    
    // College of Computer Studies
    'Associate in Computer Technology',
    'Bachelor of Science in Computer Science',
    'Bachelor of Science in Computer Science (with Specialization in Artificial Intelligence)',
    'Bachelor of Science in Information Technology',
  ];

  // List of Basic Education levels
  static const List<String> basicEducationLevels = [
    'Nursery',
    'Kindergarten',
    'Elementary',
    'Junior High School',
  ];

  // List of Senior High School strands
  static const List<String> seniorHighStrands = [
    'ABM (Accountancy, Business, and Management)',
    'GAS (General Academic Strand)',
    'HUMSS (Humanities and Social Sciences)',
    'STEM (Science, Technology, Engineering, and Mathematics)',
    'STEM Maritime',
    'ICT (Information and Communications Technology)',
    'Industrial Arts',
    'Home Economics',
    'Tech-Voc Maritime',
  ];

  // Map courses to their respective departments
  static String? getCourseDepartment(String? course) {
    if (course == null) return null;

    // Engineering courses
    if (course.contains('Computer Engineering') ||
        course.contains('Electrical Engineering') ||
        course.contains('Electronics Engineering') ||
        course.contains('Industrial Engineering') ||
        course.contains('Mechanical Engineering')) {
      return 'College of Engineering';
    }

    // Maritime courses
    if (course.contains('Marine Engineering') ||
        course.contains('Marine Transportation')) {
      return 'College of Maritime Education';
    }

    // Hospitality and Tourism courses
    if (course.contains('Hospitality Management') ||
        course.contains('Tourism Management')) {
      return 'College of Hospitality and Tourism Management';
    }

    // Nursing
    if (course.contains('Nursing')) {
      return 'College of Nursing';
    }

    // Criminology
    if (course.contains('Criminology') || course.contains('Criminal Justice')) {
      return 'College of Criminology';
    }

    // Customs
    if (course.contains('Customs Administration')) {
      return 'College of Customs Administration';
    }

    // Business and Accountancy
    if (course.contains('Accountancy') ||
        course.contains('Business Administration') ||
        course.contains('Management Accounting') ||
        course.contains('Real Estate Management')) {
      return 'College of Business and Accountancy';
    }

    // Teacher Education
    if (course.contains('Childhood Education') ||
        course.contains('Elementary Education') ||
        course.contains('Secondary Education')) {
      return 'College of Teacher Education';
    }

    // College of Computer Studies
    if (course.contains('Computer Technology') ||
        course.contains('Computer Science') ||
        course.contains('Information Technology')) {
      return 'College of Computer Studies';
    }

    return null;
  }

  // Map strands to their respective departments
  static String getStrandDepartment(String? strand) {
    if (strand == null) return 'Senior High School Department';
    return 'Senior High School Department';
  }

  // Map basic education levels to department
  static String getBasicEducationDepartment(String? level) {
    if (level == null) return 'Basic Education Department';
    return 'Basic Education Department';
  }

  // Get department for a student based on their education info
  static String? getStudentDepartment({
    String? educationLevel,
    String? course,
    String? strand,
  }) {
    if (educationLevel == 'college' && course != null) {
      return getCourseDepartment(course);
    } else if (educationLevel == 'senior_high' && strand != null) {
      return getStrandDepartment(strand);
    } else if (educationLevel == 'basic_education' || educationLevel == 'junior_high') {
      return 'Basic Education Department';
    }
    return null;
  }
}
