export const sampleQuestions = [
  {
    id: 263,
    question: "Chức năng xác lập cơ chế truy nhập đường truyền được thực hiện bởi tầng chức năng nào?",
    options: [
      "Data Link",
      "Network",
      "Transport",
      "Physical"
    ],
    correctAnswer: 1 - 1,
    explanation: true
  },
  {
    id: 264,
    question: "Chức năng xác lập chuẩn đầu nối, dây cáp, tốc độ truyền, điện áp,... được thực hiện bởi tầng chức năng nào?",
    options: [
      "Transport",
      "Network",
      "Data Link",
      "Physical"
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 265,
    question: "Ý nghĩa của dữ liệu không được gán cho các tầng nào sau đây?",
    options: [
      "Transport",
      "Network",
      "Data Link",
      "Physical"
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 266,
    question: "Khi gói tin bị mất hoặc bị lỗi thì tầng liên kết dữ liệu sẽ làm gì?",
    options: [
      "Tự khôi phục hoặc sửa lại gói tin bị mất hoặc bị lỗi đó",
      "Đưa ra yêu cầu cho trạm nguồn gửi lại gói tin bị lỗi hoặc mất",
      "Huỷ phiên trao đổi dữ liệu, đưa ra thông báo lỗi cho trạm nguồn",
      "Cả 3 ý đã nêu đều đúng."
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 267,
    question: "Thông thường, tầng liên kết dữ liệu sử dụng kỹ thuật nào để điều khiển tốc độ gửi và tốc độ nhận?",
    options: [
      "Báo nhận",
      "Kỹ thuật hàng đợi",
      "Đưa ra quy định về tốc độ gửi và tốc độ nhận",
      "Cả ba ý đã nêu đúng"
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 268,
    question: "Việc định nghĩa địa chỉ MAC tại tầng liên kết dữ liệu có ý nghĩa gì?",
    options: [
      "Để định danh một máy tính hoặc một giao diện trên mạng và cho phép các máy tính trong liên mạng có thể trao đổi thông tin với nhau",
      "Để định danh một thiết bị trên mạng và cho phép các máy tính trong một mạng có thể trao đổi thông tin với nhau.",
      "Để định danh một máy tính trên mạng",
      "Nhằm nâng cao độ tin cậy trong truyền tin"
    ],
    correctAnswer: 2 - 1,
    explanation: true
  },
  {
    id: 269,
    question: "Gói tin tại tầng liên kết dữ liệu có tên gọi là gì?",
    options: [
      "Datagram",
      "Dlink",
      "Frame",
      "Ethernet"
    ],
    correctAnswer: 1 - 1,
    explanation: true
  },
  {
    id: 270,
    question: "Tầng nào trong mô hình OSI định nghĩa địa chỉ vật lý?",
    options: [
      "Liên kết dữ liệu",
      "Vật lý",
      "Mạng",
      "Giao vận"
    ],
    correctAnswer: 1 - 1,
    explanation: true
  },
  {
    id: 271,
    question: "Chức năng cơ bản của tầng liên kết dữ liệu là gì?",
    options: [
      "Định địa chỉ vật lý",
      "Điều khiển truy nhập đường truyền",
      "Điều khiển kết nối logic",
      "Tất cả các chức năng đã nêu."
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 272,
    question: "Chức năng cơ bản của tầng vật lý trong mô hình OSI là gì?",
    options: [
      "Chuyển đổi dữ liệu số trong máy tính thành tín hiệu đường truyền và ngược lại",
      "Thiết lập địa chỉ vật lý",
      "Xác định phương thức truyền thông và tốc độ truyền thông",
      "Chuyển đổi dữ liệu số trong máy tính thành tín hiệu đường truyền và ngược lại, Xác định phương thức truyền thông và tốc độ truyền thông"
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 273,
    question: "Dữ liệu tại tầng vật lý trong mô hình OSI có cấu trúc như thế nào?",
    options: [
      "Có cấu trúc header và chuỗi các bit",
      "Là chuỗi các bit nhị phân có cấu trúc",
      "Là chuỗi các bit nhị phân không có cấu trúc",
      "Không có dữ liệu tại tầng vật lý"
    ],
    correctAnswer: 3 - 1,
    explanation: true
  },
  {
    id: 274,
    question: "Chức năng nào sau đây không là chức năng của tầng vật lý?",
    options: [
      "Định địa chỉ IP",
      "Thiết lập khuôn dạng gói tin",
      "Thích ứng với đường truyền mạng",
      "Định nghĩa IP và thiết lập khuôn dạng gói tin."
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 275,
    question: "Tầng liên kết dữ liệu có thể thực hiện chức năng nào sau đây?",
    options: [
      "Cung cấp chức năng phát hiện và khắc phục lỗi đối với mỗi gói dữ liệu truyền thông",
      "Điều khiển tốc độ truyền tin",
      "Thực hiện điều khiển việc truy cập đường truyền chung",
      "Cả 3 ý đã nêu đều đúng."
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 276,
    question: "Tầng nào trong mô hình OSI làm việc với các tín hiệu điện:",
    options: [
      "Data Link.",
      "Network.",
      "Physical.",
      "Session"
    ],
    correctAnswer: 3 - 1,
    explanation: true
  },
  {
    id: 277,
    question: "Đơn vị dữ liệu của tầng Physical là:",
    options: [
      "Frame",
      "Packet",
      "Segment",
      "Bit"
    ],
    correctAnswer: 4 - 1,
    explanation: true
  }
];
