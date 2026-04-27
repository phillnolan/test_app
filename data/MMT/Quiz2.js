export const sampleQuestions = [
  {
    id: 50,
    question: "Chuẩn IEEE nào định nghĩa chuẩn kết nối dành cho mạng cục bộ dựa trên Ethernet?",
    options: [
      "802.3",
      "802.5",
      "802.12",
      "802.11b"
    ],
    correctAnswer: 1 - 1,
    explanation: true
  },
  {
    id: 51,
    question: "Chuẩn IEEE nào định nghĩa chuẩn kết nối dành cho mạng Wireless LAN?",
    options: [
      "802.3",
      "802.5",
      "802.6",
      "802.11"
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 52,
    question: "Chuẩn IEEE nào định nghĩa chuẩn kết nối dành cho mạng dạng vòng (Ring)?",
    options: [
      "802.3",
      "802.5",
      "802.11",
      "802.11b"
    ],
    correctAnswer: 2 - 1,
    explanation: true
  },
  {
    id: 53,
    question: "Trong mạng dạng tuyến (BUS), Terminator dùng để làm gì?",
    options: [
      "Kết nối giữa mạng dạng tuyến với các mạng khác",
      "Tránh sự phản xạ của sóng điện từ khi lan truyền đến cuối sợi cáp",
      "Tăng cường năng lượng của sóng điện từ",
      "Dùng để khử nhiễu trong sóng điện từ"
    ],
    correctAnswer: 2 - 1,
    explanation: true
  },
  {
    id: 54,
    question: "Trạng thái của mạng dạng BUS sẽ như thế nào nếu không có Terminator?",
    options: [
      "Mạng vẫn hoạt động bình thường nhưng tốc độ truyền thông chậm",
      "Mạng không hoạt động được",
      "Mạng vẫn hoạt động bình thường và không có khả năng mở rộng",
      "Mạng vẫn hoạt động bình thường và hiệu suất truyền tin giảm"
    ],
    correctAnswer: 2 - 1,
    explanation: true
  },
  {
    id: 55,
    question: "Mạng dạng tuyến (Bus) kết nối các máy tính theo phương thức",
    options: [
      "Điểm - điểm",
      "Điểm - nhiều điểm",
      "Hỗn hợp",
      "Cả 3 ý đã nêu đều sai"
    ],
    correctAnswer: 2 - 1,
    explanation: true
  },
  {
    id: 56,
    question: "Nguyên nhân nào có thể gây ra lỗi kết nối trao đổi thông tin giữa hai máy trạm trong mạng dạng tuyến?",
    options: [
      "Do thiết bị Terminator bị lỗi",
      "Do đầu nối giữa máy trạm và đường truyền chính (T-Connector) bị lỗi",
      "Do có nhiều cặp máy trạm trên mạng trao đổi thông tin đồng thời",
      "Do thiết bị Terminator bị lỗi hoặc do đầu nối giữa máy trạm và đường truyền chính (T-Connector) bị lỗi."
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 57,
    question: "Nguyên nhân nào có thể dẫn đến giảm hiệu suất truyền thông trong một LAN?",
    options: [
      "Do có nhiều cặp máy tính trong mạng trao đổi thông tin với lưu lượng cao",
      "Do Virus chiếm dụng băng thông của đường truyền",
      "Do thiết bị truyền thông có năng lực kém",
      "Do có nhiều cặp máy tính trong mạng trao đổi thông tin với lưu lượng cao hoặc do Virus chiếm dụng băng thông của đường truyền"
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 58,
    question: "Mạng dạng vòng (Ring) kết nối các máy tính theo phương thức",
    options: [
      "Điểm - điểm",
      "Điểm - nhiều điểm",
      "Điểm - một số điểm",
      "Cả ba phương thức đã nêu đều đúng"
    ],
    correctAnswer: 1 - 1,
    explanation: true
  },
  {
    id: 59,
    question: "Nguyên nhân nào có thể gây ra lỗi kết nối trao đổi thông tin giữa hai máy trạm trong mạng dạng vòng (Ring)?",
    options: [
      "Do thẻ bài bị mất",
      "Do đầu nối giữa máy trạm và đường truyền chính bị lỗi",
      "Do mạng bị tắc nghẽn",
      "Do thẻ bài bị mất hoặc do đầu nối giữa máy trạm và đường truyền chính bị lỗi."
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 60,
    question: "Nhược điểm chính của mạng dạng vòng (Ring) là gì?",
    options: [
      "Đường dây cần phải khép kín, nếu bị ngắt ở một nơi nào đó thì toàn bộ hệ thống cũng bị ngừng hoạt động.",
      "Tốc độ trao đổi thông tin chậm",
      "Tốn nhiều dây cáp, hiệu suất đường truyền thấp",
      "Khó có khả năng mở rộng mạng"
    ],
    correctAnswer: 1 - 1,
    explanation: true
  },
  {
    id: 61,
    question: "Ưu điểm chính của mạng dạng vòng (Ring) là gì?",
    options: [
      "Có thể nới rộng đường truyền chính, ít tốn kém đường truyền mạng, hiệu suất của đường truyền có thể đạt tới gần 100%",
      "Nhiều cặp máy trạm có thể trao đổi thông tin đồng thời",
      "Khi một trạm nào đó ngừng hoạt động thì hệ thống mạng vẫn hoạt động bình thường.",
      "Giao thức truyền dữ liệu đơn giản hơn so với mạng dạng sao"
    ],
    correctAnswer: 1 - 1,
    explanation: true
  },
  {
    id: 62,
    question: "Mạng dạng vòng tròn (Ring) là gì?",
    options: [
      "Các máy tính và các thiết bị được nối với nhau bởi đường truyền dẫn chung được giới hạn bởi hai đầu nối Terminator",
      "Các máy tính hay các thiết bị được nối với nhau bởi đường truyền dẫn chung dạng vòng khép kín, mỗi thiết bị hay các máy tính được nối với đường truyền bởi thiết bị Repeater",
      "Các máy tính và các thiết bị được nối với nhau bởi thiết bị xử lý truyền thông trung tâm như Hub/Switch",
      "Các máy tính và các thiết bị được nối trực tiếp với nhau"
    ],
    correctAnswer: 2 - 1,
    explanation: true
  },
  {
    id: 63,
    question: "Mô hình kết nối mạng (topo) của LAN là gì?",
    options: [
      "Star",
      "Bus",
      "Ring",
      "Một trong những mô hình kết nối mạng đã nêu."
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 64,
    question: "Mạng dạng hình sao là gì?",
    options: [
      "Các máy tính và các thiết bị được nối với nhau bởi đường truyền dẫn chung được giới hạn bởi hai đầu nối Terminator",
      "Các máy tính và các thiết bị được nối với nhau bởi đường truyền dẫn chung dạng vòng khép kín",
      "Các máy tính và các thiết bị được nối với nhau bởi thiết bị xử lý truyền thông trung tâm.",
      "Các máy tính và các thiết bị được nối trực tiếp với nhau"
    ],
    correctAnswer: 3 - 1,
    explanation: true
  },
  {
    id: 65,
    question: "Ưu điểm của mạng dạng sao là gì?",
    options: [
      "Nếu có một máy trạm nào đó trong mạng bị hỏng thì mạng vẫn hoạt động bình thường",
      "Mạng có thể mở rộng hoặc thu hẹp tuỳ theo yêu cầu của người sử dụng",
      "Dễ dàng kiểm soát và khắc phục sự cố",
      "Nếu có một máy trạm nào đó trong mạng bị hỏng thì mạng vẫn hoạt động bình thường, dễ dàng kiểm soát và khắc phục sự cố"
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 66,
    question: "Nhược điểm của mạng dạng sao là gì?",
    options: [
      "Khi thiết bị xử lý truyền thông trung tâm bị hỏng thì cả hệ thống ngưng hoạt động",
      "Khả năng mở rộng mạng phụ thuộc vào khả năng xử lý truyền thông của thiết bị trung tâm.",
      "Việc cấu hình lại mạng là rất khó khăn",
      "Khi thiết bị xử lý truyền thông trung tâm bị hỏng thì cả hệ thống ngưng hoạt động hoặc khả năng mở rộng mạng phụ thuộc vào khả năng xử lý truyền thông của thiết bị trung tâm."
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 67,
    question: "Nguyên nhân nào có thể gây ra lỗi kết nối truyền thông giữa hai trạm trong mạng dạng sao (star)?",
    options: [
      "Do thiết bị trung tâm bị lỗi",
      "Do đường truyền bị lỗi",
      "Do có nhiều cặp máy trạm khác cùng trao đổi thông tin đồng thời",
      "Do thiết bị trung tâm bị lỗi hoặc do đường truyền bị lỗi."
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 68,
    question: "Để mở rộng kết nối của mạng dạng sao, về cơ bản người ta phải làm gì?",
    options: [
      "Nâng cao năng lực xử lý truyền thông của thiết bị trung tâm",
      "Nâng cao năng lực tính toán của mỗi máy trạm",
      "Cài đặt bổ sung phần mềm mạng vào các máy trạm",
      "Nâng cao năng lực xử lý truyền thông của thiết bị trung tâm hoặc cài đặt bổ sung phần mềm mạng vào các máy trạm."
    ],
    correctAnswer: 1 - 1,
    explanation: true
  },
  {
    id: 69,
    question: "Công nghệ LAN nào được sử dụng rộng rãi nhất hiện nay?",
    options: [
      "Token Ring",
      "Ethernet",
      "FDDI",
      "ArcNet"
    ],
    correctAnswer: 2 - 1,
    explanation: true
  },
  {
    id: 70,
    question: "Băng thông (Bandwith) là gì?",
    options: [
      "Là dung lượng đường truyền được xác định bằng mật độ dữ liệu truyền thông",
      "Là tốc độ truyền dữ liệu cho phép tối đa của đường truyền",
      "Là đường truyền thông dữ liệu",
      "Là dung lượng đường truyền được xác định bằng mật độ dữ liệu truyền thông và là tốc độ truyền dữ liệu cho phép tối đa của đường truyền"
    ],
    correctAnswer: 2 - 1,
    explanation: true
  },
  {
    id: 71,
    question: "Mbps (Đơn vị tốc độ truyền thông) là viết tắt của cụm từ nào?",
    options: [
      "Mega Bytes Per Second",
      "Mega Bit Protocol Second",
      "Mega Bit Per Sequence",
      "Mega Bits Per Second"
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 72,
    question: "Mạng diện rộng thường do bao nhiêu cơ quan tham hay tổ chức gia quản lý?",
    options: [
      "Một cơ quan",
      "Hai cơ quan",
      "Ba cơ quan",
      "Nhiều cơ quan"
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 73,
    question: "Mạng diện rộng thường sử dụng hạ tầng truyền dẫn của nhà cung cấp dịch vụ truyền thông công cộng như các công ty điện thoại, đúng hay sai?",
    options: [
      "Thường sử dụng hạ tầng truyền dẫn của nhà cung cấp dịch vụ truyền thông công cộng như các công ty điện thoại",
      "Thường xây dựng cơ sở hạ tầng truyền dẫn riêng",
      "Thường kết hợp sử dụng hạ tầng truyền dẫn của nhà cung cấp dịch vụ truyền thông công cộng và cơ sở hạ tầng riêng phần của các mạng này",
      "Tất cả các ý đã nêu đều đúng."
    ],
    correctAnswer: 1 - 1,
    explanation: true
  },
  {
    id: 74,
    question: "Ưu điểm của mạng diện rộng so với mạng cục bộ là",
    options: [
      "Cho phép kết nối các máy tính trên một phạm vi lớn",
      "Tốc độ truyền thông cao",
      "Độ tin cậy cao",
      "Cho phép kết nối các máy tính trên một phạm vi lớn và độ tin cậy cao"
    ],
    correctAnswer: 1 - 1,
    explanation: true
  },
  {
    id: 75,
    question: "Phát biểu về Mạng diện rộng và mạng cục bộ nào đúng?",
    options: [
      "Mạng diện rộng thường có tốc độ truyền thông cao hơn so với mạng cục bộ",
      "Mạng diện rộng thường có tốc độ truyền thông thấp hơn so với mạng cục bộ",
      "Mạng diện rộng thường có tốc độ truyền thông ngang bằng so với mạng cục bộ",
      "Rất khó so sánh tốc độ truyền thông giữa mạng diện rộng và mạng cục bộ"
    ],
    correctAnswer: 2 - 1,
    explanation: true
  },
  {
    id: 76,
    question: "Tại sao mạng diện rộng lại có độ tin cậy thấp so với mạng cục bộ?",
    options: [
      "Do chịu ảnh hưởng nhiều các tác động từ môi trường",
      "Do phạm vi kết nối đường truyền lớn",
      "Do tốc độ truyền thông cao",
      "Do chịu ảnh hưởng nhiều các tác động từ môi trường và do phạm vi kết nối đường truyền lớn"
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 77,
    question: "Phát biểu nào sau đây đúng?",
    options: [
      "Trong mạng chuyển mạch kênh các dữ liệu chuyển từ trạm nguồn cho tới trạm đích theo một đường truyền được xác định trước.",
      "Trong mạng chuyển mạch kênh các dữ liệu chuyển từ trạm nguồn cho tới trạm đích theo nhiều đường truyền khác nhau.",
      "Trong mạng chuyển mạch kênh một trạm có thể trao đổi thông tin đồng thời với nhiều trạm khác.",
      "Tốc độ truyền thông của mạng chuyển mạch kênh chậm hơn so với mạng chuyển mạch gói"
    ],
    correctAnswer: 1 - 1,
    explanation: true
  },
  {
    id: 78,
    question: "Phát biểu nào sau đây là sai?",
    options: [
      "Trong mạng chuyển mạch gói, các dữ liệu chuyển từ trạm nguồn cho tới trạm đích theo một đường truyền được xác định trước và không thay đổi trong quá trình truyền",
      "Trong mạng chuyển mạch gói, các dữ liệu chuyển từ trạm nguồn cho tới trạm đích theo nhiều đường truyền khác nhau",
      "Trong mạng chuyển mạch gói, một trạm chỉ có thể trao đổi thông tin với nhiều trạm khác tại cùng một thời điểm",
      "Tốc độ truyền thông của mạng chuyển mạch gói chậm hơn so với mạng chuyển mạch kênh"
    ],
    correctAnswer: 1 - 1,
    explanation: true
  },
  {
    id: 79,
    question: "Mạng internet là mạng thuộc loại mạng nào?",
    options: [
      "Mạng chuyển mạch kênh",
      "Mạng chuyển mạch gói",
      "Mạng quảng bá",
      "Không thuộc cả 3 loại mạng đã nêu (mạng toàn cầu)"
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 80,
    question: "Nguyên nhân dẫn đến hiệu suất truyền thông của mạng chuyển mạch gói cao hơn so với mạng chuyển mạch kênh?",
    options: [
      "Do dữ liệu được chia thành các gói tin được truyền theo nhiều đường khác nhau trên mạng cho tới đích",
      "Do tại cùng một thời điểm có nhiều trạm được phép cùng sử dụng chung hạ tầng truyền thông của mạng để trao đổi thông tin",
      "Do năng lực truyền thông của hạ tầng mạng chuyển mạch gói mạnh hơn so với năng lực truyền thông của mạng chuyển mạch kênh",
      "Do dữ liệu được chia thành các gói tin được truyền theo nhiều đường khác nhau trên mạng cho tới đích và do tại cùng một thời điểm có nhiều trạm được phép cùng sử dụng chung hạ tầng truyền thông của mạng để trao đổi thông tin"
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 81,
    question: "Mạng điện thoại công cộng là một mạng thuộc loại mạng nào?",
    options: [
      "Mạng quảng bá",
      "Mạng chuyển mạch gói",
      "Mạng chuyển mạch kênh",
      "Cả 3 loại mạng đã nêu"
    ],
    correctAnswer: 3 - 1,
    explanation: true
  },
  {
    id: 82,
    question: "Hầu kết các loại mạng diện rộng hiện nay",
    options: [
      "Là mạng chuyển mạch kênh",
      "Là mạng chuyển mạch gói",
      "Là mạng quảng bá",
      "Là sự kết hợp giữa các loại mạng chuyển mạch kênh, chuyển mạch gói, mạng quảng bá."
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 83,
    question: "Các hoạt động truyền dữ liệu chính qua mạng chuyển mạch kênh là gì?",
    options: [
      "Thiết lập kết nối vật lý, truyền dữ liệu, nhận dữ liệu, giải phóng kết nối vật lý",
      "Gửi dữ liệu, kiểm tra và nhận dữ liệu",
      "Thiết lập kết nối logic, truyền dữ liệu, giải phóng kết nối logic",
      "Thiết lập kết nối vật lý, truyền dữ liệu, nhận dữ liệu, giải phóng kết nối vật lý và Thiết lập kết nối logic, truyền dữ liệu, giải phóng kết nối logic."
    ],
    correctAnswer: 1 - 1,
    explanation: true
  },
  {
    id: 84,
    question: "Intranet là gì?",
    options: [
      "Mạng con của Internet",
      "Mạng cục bộ kiểu Ethernet",
      "Mạng cục bộ sử dụng công nghệ Internet",
      "Mạng diện rộng theo chuẩn Internet"
    ],
    correctAnswer: 3 - 1,
    explanation: true
  },
  {
    id: 85,
    question: "VPN (Virtual Private Network ) là gì?",
    options: [
      "Là LAN sử dụng công nghệ Internet như TCP/IP",
      "Là WAN sử dụng công nghệ Internet như TCP/IP",
      "Là mạng riêng của một tổ chức bao gồm có nhiều điểm kết nối tới LAN trung tâm sử dụng hạ tầng hệ thống mạng công cộng",
      "Là LAN có sử dụng công nghệ Web"
    ],
    correctAnswer: 3 - 1,
    explanation: true
  },
  {
    id: 86,
    question: "Có bao nhiêu tổ chức quản lý VPN ?",
    options: [
      "Có một tổ chức quản lý",
      "Có nhiều tổ chức tham gia quản lý bao gồm nhà cung cấp dịch vụ và tổ chức sử dụng VPN,...",
      "Do tổ chức sử dụng VPN quản lý",
      "Có một tổ chức quản lý và Do tổ chức sử dụng VPN quản lý"
    ],
    correctAnswer: 2 - 1,
    explanation: true
  },
  {
    id: 87,
    question: "Đặc điểm chung giữa hai máy tính trong một LAN là gì?",
    options: [
      "Có cùng địa chỉ IP",
      "Có cùng địa chỉ MAC",
      "Có cùng địa chỉ mạng",
      "Có cùng địa chỉ IP và cùng địa chỉ mạng"
    ],
    correctAnswer: 3 - 1,
    explanation: true
  },
  {
    id: 88,
    question: "Đặc điểm phân biệt giữa hai máy tính ở hai LAN khác nhau là gì?",
    options: [
      "Có cùng địa chỉ IP",
      "Có cùng địa chỉ MAC",
      "Có địa chỉ mạng khác nhau",
      "Có cùng địa chỉ IP và cùng địa chỉ MAC"
    ],
    correctAnswer: 3 - 1,
    explanation: true
  },
  {
    id: 89,
    question: "TCP/IP là thuật ngữ viết tắt của cụm từ nào?",
    options: [
      "Transfer Control Protocol/Internet Protocol",
      "Transmission Control Protocol/Internet Protocol",
      "Transmission Control Protocol/Interconnection Protocol",
      "Transfer Communication Protocol/Internet Protocol"
    ],
    correctAnswer: 2 - 1,
    explanation: true
  },
  {
    id: 90,
    question: "Bộ phần mềm giao thức TCP/IP được tích hợp vào phần mềm nào sau đây?",
    options: [
      "Trình điều khiển (Driver) cho Card mạng",
      "Hệ điều hành Linux",
      "Hệ điều hành Windows XP",
      "Hệ điều hành Linux và Hệ điều hành Windows XP"
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 91,
    question: "TCP/IP là gì?",
    options: [
      "Là một bộ giao thức cho phép LAN kết nối với LAN",
      "Là một bộ giao thức cho phép LAN kết nối với WAN",
      "Là một bộ giao thức cho phép WAN kết nối với WAN",
      "Là một bộ giao thức cho phép truyền thông dữ liệu thông qua nhiều mạng khác nhau."
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 92,
    question: "Việt Nam chính thức gia nhập vào Internet bắt đầu vào năm nào?",
    options: [
      "1995",
      "1996",
      "1997",
      "1998"
    ],
    correctAnswer: 3 - 1,
    explanation: true
  },
  {
    id: 93,
    question: "Khẳng định nào sau đây là đúng",
    options: [
      "Internet sử dụng bộ giao thức chung TCP/IP để trao đổi thông tin",
      "Internet sử dụng giao thức chung TCP để trao đổi thông tin",
      "Internet sử dụng giao thức chung IP để trao đổi thông tin",
      "Internet sử dụng bộ giao thức chung UDP/IP để trao đổi thông tin"
    ],
    correctAnswer: 1 - 1,
    explanation: true
  },
  {
    id: 94,
    question: "Máy khách trong mô hình Khách/Chủ thực hiện chức năng gì?",
    options: [
      "Gửi yêu cầu truy nhập thông tin tới máy chủ",
      "Gửi yêu cầu truy nhập thông tin tới máy chủ và tiếp nhận, thể hiện kết quả cho người dùng",
      "Tiếp nhận yêu cầu từ máy chủ và gửi kết quả trả về cho máy chủ",
      "Xử lý các thông tin do máy chủ yêu cầu"
    ],
    correctAnswer: 2 - 1,
    explanation: true
  },
  {
    id: 95,
    question: "Máy chủ trong mô hình Khách/Chủ thực hiện chức năng gì?",
    options: [
      "Gửi yêu cầu truy nhập thông tin tới máy khách",
      "Gửi thông tin tới máy khách theo yêu cầu và tiếp nhận yêu cầu, tổ chức lưu trữ.",
      "Tiếp nhận yêu cầu từ máy khách, xử lý yêu cầu và gửi kết quả trả về cho máy khách",
      "Xử lý các thông tin do máy khách yêu cầu"
    ],
    correctAnswer: 2 - 1,
    explanation: true
  },
  {
    id: 96,
    question: "Dịch vụ WWW (World Wide Web) hoạt động trao đổi thông tin theo giao thức nào?",
    options: [
      "FTP",
      "HTTP",
      "SMTP",
      "DHCP"
    ],
    correctAnswer: 2 - 1,
    explanation: true
  },
  {
    id: 97,
    question: "Phần mềm nào sau đây có chức năng dành cho máy khách của dịch vụ E-mail?",
    options: [
      "Netscape Navigator",
      "Internet Explore",
      "FireFox",
      "Outlook Express"
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 98,
    question: "HTML là thuật ngữ viết tắt của cụm từ nào?",
    options: [
      "HyperText Markup Language",
      "HyperText Made Language",
      "HybridText Markup Language",
      "HyperText Markup Locator"
    ],
    correctAnswer: 1 - 1,
    explanation: true
  },
  {
    id: 99,
    question: "Siêu văn bản có chứa dạng dữ liệu nào sau đây?",
    options: [
      "Văn bản",
      "Âm thanh",
      "Hình ảnh",
      "Cả ba dạng dữ liệu trên"
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 107,
    question: "Trong trang Web tìm kiếm văn bản Web www.google.com.vn, từ khoá tìm kiếm: “Hà Nội” + “Mùa Thu” có ý nghĩa gì?",
    options: [
      "Tìm kiếm các văn bản Web có chứa từ “Hà Nội Mùa Thu”",
      "Tìm kiếm các văn bản Web có chứa từ “Hà Nội” hoặc có chứa từ “Mùa Thu”",
      "Tìm kiếm các văn bản Web có chứa cả 2 từ “Hà Nội” và “Mùa Thu”",
      "Tìm kiếm các văn bản Web có chứa từ “Hà Nội” và không có từ “Mùa Thu”"
    ],
    correctAnswer: null,
    explanation: true
  },
  {
    id: 108,
    question: "Khi sử dụng mạng máy tính ta sẽ được các lợi ích:",
    options: [
      "Chia sẻ tài nguyên (ổ cứng, cơ sở dữ liệu, máy in, các phần mềm tiện ích, ...)",
      "Quản lý tập trung, bảo mật và backup tốt",
      "Sử dụng các dịch vụ mạng.",
      "Tất cả đều đúng."
    ],
    correctAnswer: null,
    explanation: true
  },
  {
    id: 109,
    question: "Kỹ thuật dùng để nối kết nhiều máy tính với nhau trong phạm vi một văn phòng gọi là:",
    options: [
      "LAN",
      "WAN",
      "MAN",
      "Internet"
    ],
    correctAnswer: 1 - 1,
    explanation: true
  },
  {
    id: 110,
    question: "Mạng Internet là sự phát triển của:",
    options: [
      "Các hệ thống mạng LAN",
      "Các hệ thống mạng WAN.",
      "Các hệ thống mạng Intranet.",
      "Cả ba câu đều đúng."
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 111,
    question: "Phát biểu nào sau đây mô tả đúng nhất cho cấu hình Star",
    options: [
      "Cần ít cáp hơn nhiều so với các cấu hình khác.",
      "Khi cáp đứt tại một điểm nào đó làm toàn bộ mạng ngưng hoạt động.",
      "Khó tái lập cấu hình hơn so với các cấu hình khác.",
      "Dễ kiểm soát và quản lý tập trung."
    ],
    correctAnswer: 4 - 1,
    explanation: true
  },
  {
    id: 112,
    question: "Mô tả nào thích hợp cho mạng Bus",
    options: [
      "Cần nhiều cáp hơn các cấu hình khác.",
      "Phương tiện rẻ tiền và dễ sử dụng.",
      "Dễ sửa chữa hơn các cấu hình khác.",
      "Số lượng máy trên mạng không ảnh hưởng đến hiệu suất mạng."
    ],
    correctAnswer: 2 - 1,
    explanation: true
  },
  {
    id: 113,
    question: "Việc nhiều các gói tin bị đụng độ trên mạng sẽ làm cho:",
    options: [
      "Hiệu quả truyền thông của mạng tăng lên",
      "Hiệu quả truyền thông của mạng kém đi",
      "Hiệu quả truyền thông của mạng không thay đổi",
      "Phụ thuộc vào các ứng dụng mạng mới tính được hiệu quả"
    ],
    correctAnswer: 2 - 1,
    explanation: true
  },
  {
    id: 114,
    question: "Đơn vị của “băng thông là”:",
    options: [
      "Hertz (Hz).",
      "Volt (V).",
      "Bit/second (bps).",
      "Ohm (Ω)"
    ],
    correctAnswer: 3 - 1,
    explanation: true
  }
];
