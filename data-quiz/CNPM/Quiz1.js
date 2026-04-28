export const sampleQuestions = [
    {
        id: 0,
        question: "Để xây dựng các biểu đồ như: Biểu đồ phân dã chức năng (FDD - Funtion Decomposition Diagram), Biểu đồ luồng dữ liệu (DFD - DataFlow Diagram), Biểu đồ quan hệ thực thể (ERD - Entily Relationship Diagram), Biểu đồ ca sử dụng (Use-case Diagram), Biểu đồ trình tự (Sequence Diagram), nhóm phát triển phầm mềm phải căn cứ vào đâu?",
        options: [
            "Dựa vào yêu cầu phần mềm của khách hàng",
            "Dựa vào quan điểm của trưởng nhóm phát triển",
            "Dựa vào ý kiến chủ quan của nhóm lập trình",
        ],
        correctAnswer: 0,
        explanation: "True"
    },
    {
        id: 1,
        question: "Những phát biểu nào sau đây đúng liên quan đến công việc găng (critical task) và đường găng (critial path) trong phương pháp CPM?",
        options: [
            "Công việc găng là các công việc có trữ lượng thời gian (thời gian tự do) lớn hơn 0",
            "Công việc găng là các công việc có trữ lượng thời gian (thời gian tự do) bằng 0",
            "Độ dài của đường găng trên trục thời gian chính là thời gian lớn nhất để hoàn thành dự án theo lịch trình",
            "Đường găng là đường dài nhất đi xuyên mạng đi từ thời điểm bắt đầu tới thời điểm kết thúc đi qua các công việc găng",
        ],
        correctAnswer: [1, 3],
        explanation: "True"
    },
    {
        id: 3,
        question: "Các kiểu sơ đồ, biểu đồ nào sau đây có thể sử dụng để đặc tả yêu cầu?",
        options: [
            "Biểu đồ trình tự (Sequence Diagram)",
            "Biểu đồ quan hệ thực thể (Entity Relationship Diagram)",
            "Biểu đồ phân rã chức năng(Functional Decomposition Diagram)",
            "Sơ đồ hoạt động (AoA,AoN)",
            "Biểu đồ ca sử dụng (Use-case Diagram)",
            "Biểu đồ luồng dữ liệu (Data Flow Diagram)",
            "Lược đồ cơ sở dữ liệu",
        ],
        correctAnswer: [0, 1, 2, 4, 5],
        explanation: "True"
    },
    {
        id: 4,
        question: "Những phát biểu nào dưới đây được coi là yêu cầu phi chức năng?",
        options: [
            "Sau khi hệ thống khởi động trở lại, tất cả các chức năng phải được khôi phục trong vòng 5 phút",
            "Hệ thống cần tối ưu",
            "Mô hình phát triển phần mềm được sử dụng trong dự án là Scrum",
            "Giao diện gây ấn tượng thân thiện",
            "Hệ thống sẽ không tiết lộ bất kỳ thông tin về khách hàng ngoài tên và số tham chiếu của họ cho người vận hành hệ thống",

        ],
        correctAnswer: [0, 2, 4],
        explanation: "True"
    },
    {
        id: 5,
        question: "Chỉ ra đâu là mối quan hệ giữa Tổng thể - bộ phận chặt trong các mối quan hệ giữa các lớp đối tượng ?",
        options: [
            "Quan hệ liên kết (Association)",
            "Quan hệ phụ thuộc (Dependency)",
            "Quan hệ kết hợp (Composition)",
            "Quan hệ tập hợp (Aggregation)",
            "Quan hệ hiện thực hóa (Realization)",
            "Quan hệ kế thừa/tổng quát hóa (Generalization)",

        ],
        correctAnswer: 2,
        explanation: "True"
    },
    {
        id: 6,
        question: "Những phát biểu nào sau đây là đúng liên quan đến công việc găng (critical task) trong phương pháp CPM?",
        options: [
            "Công việc găng là các công việc có trữ lượng thời gian(thời gian tự do) bằng 0",
            "Công việc găng là các công việc có trữ lượng thời gian (thời gian tự do) lớn hơn 0",
            "Công việc găng là công việc mà người dùng không có thời gian nghỉ",
            "Công việc găng là các công việc có trữ lượng thời gian (thời gian tự do) bằng 1",
        ],
        correctAnswer: [0],
        explanation: "True"
    },
    {
        id: 7,
        question: "Ý nào sau đây không phải là phong cách thiết kế kiến trúc phần mềm?",
        options: [
            "Phong cách chia nhỏ module",
            "Phong cách điều khiển",
            "Phong cách tổ chức",
            "Phong cách hướng kế hoạch",
        ],
        correctAnswer: 3,
        explanation: "True"
    },
    {
        id: 8,
        question: "Các thuật ngữ nào sau đây xuất hiện trong mô hình scrum??",
        options: [
            "Sprint backlog",
            "Scrum Master",
            "User Story",
            "Spiral Model",
            "waterfall model",
            "Sprint",
            "Scrum member",
        ],
        correctAnswer: [0, 1, 2, 5],
        explanation: "True"
    },
    {
        id: 9,
        question: "Các mối liên hệ giữa các lớp trong sơ đồ lớp được hỗ trợ bởi UML là gì?",
        options: [
            "Liên kết (Association)",
            "Hiện thực hóa (Realization)",
            "Bao gồm (Include)",
            "Kế thừa (Generalization) hoặc Tổng quát hóa",
            "Sở hữu lỏng (Aggregation) hoặc Toàn bộ - bộ phận lỏng",
            "Sở hữu chặt (Composition) hoặc Toàn bộ - bộ phận chặt",
            "Phụ thuộc (Dependency)",
            "Mở Rộng (Extend)",
        ],
        correctAnswer: [0, 1, 3, 4, 5, 6],
        explanation: "True"
    },
    {
        id: 10,
        question: "Khi thiết kế dữ liệu, chúng ta cần phải thỏa mãn những yêu cầu nào sau đây?",
        options: [
            "Tính tiến hóa",
            "Hiệu quả về truy xuất và lưu trữ",
            "Tính đúng đắn",
            "Thiết kế cần ràng buộc với dữ liệu",

        ],
        correctAnswer: [0, 1, 2],
        explanation: "True"
    },
    {
        id: 11,
        question: "Khi lập kế hoạch quản lý dự án phần mềm, các kế hoạch cần đề cập đến:",
        options: [
            "Phân chia công việc",
            "Các nguồn lực có sẵn cho dự án",
            "Tính khả thi của dự án",
            "Người dùng cuối (End User)",
            "Lịch trình cho công việc",

        ],
        correctAnswer: [0, 1, 4],
        explanation: "True"
    },
    {
        id: 12,
        question: "Những sự khác nhau giữa Mô hình phát triển tiến hoá và Mô hình phân phối gia tăng là gì?",
        options: [
            "Mô hình phát triển tiến hoá cần tương tác thường xuyên với khách hàng, trong khi đó Mô hình phân phối gia tăng KHÔNG cần tương tác thường xuyên với khách hàng",
            "Số lần lặp quy trình trong Mô hình phát triển tiến hoá là biết trước, trong khi số lần lặp quy trình trong Mô hình phân phối gia tăng là KHÔNG biết trước",
            "Mô hình phát triển tiến hoá chỉ cần có miêu tả phác thảo về phần mềm là có thể bắt đầu tiến hành dự án, trong khi đó để bắt đầu tiến hành dự án. Mô hình phân phối gia tăng, chúng ta cần phải có yêu cầu rõ ràng về phần mềm",
        ],
        correctAnswer: 2,
        explanation: "True"
    },
    {
        id: 13,
        question: "Phát biểu nào sau đây là ĐÚNG về Mô hình phân phối gia tăng?",
        options: [
            "Mô hình phân phối gia tăng thích hợp với các dự cần quản trị rủi ro",
            "Mô hình phân phối gia tăng thích hợp với những dự án có yêu cầu KHÔNG cần rõ ràng ngay từ đầu",
            "Trong mô hình này, quá trình phát triển và phân phối được chia ra thành nhiều vòng, mỗi vòng sẽ phát triển và phân phối một tập con các chức năng được yêu cầu",
        ],
        correctAnswer: [2],
        explanation: "True"
    },
    {
        id: 14,
        question: "Giả sử có 2 lớp Khách hàng va Sản phẩm, mối quan hệ giữa hai lớp này có thể là gì?",
        options: [
            "Association",
            "Composition",
            "OptioGeneralization",
            "Aggregation",
        ],
        correctAnswer: [0],
        explanation: "True"
    },
    {
        id: 15,
        question: "Hãy chọn những ý đúng cho phong cách tương tác trong thiết kế giao diện?",
        options: [
            "Ngôn ngữ lệnh",
            "Thao tác trực tiếp",
            "Điền biểu mẫu",
            "Dựa trên kinh nghiệm",
            "Lựa chọn menu",
            "Điều khiển lệnh",
        ],
        correctAnswer: [0, 1, 2, 4],
        explanation: "True"
    },
    {
        id: 16,
        question: "Những phát biểu nào dưới đây được coi là Yêu cầu phi chức năng?",
        options: [
            "Hệ thống không được tiết lộ bất kỳ thông tin về khách hàng ngoài tên và số tham chiếu của họ cho người vận hành hệ thống",
            "Hiệu suất của chương trình phải được tối ưu nhất có thể",
            "Giao diện phải thân thiện, dễ dùng với người dùng cuối",
            "Mô hình phát triển phần mềm được sử dụng trong dự án là Scrum",
            "Ngôn ngữ lập trình được sử dụng để phát triển phần mềm là Java",
        ],
        correctAnswer: [0, 3, 4],
        explanation: "True"
    },
    {
        id: 17,
        question: "những phát biểu nào sau đây là đúng khi so sánh giữa mô hình phân tầng và mô hình MVC (Model-View-Control)?",
        options: [
            "Trong mô hình MVC, các thành phần cũng được xếp thành các tầng chồng lên nhau giống như Mô hình phân tầng, trong đó thành phần ở tầng trên sử dụng dịch vụ được cung cấp bởi tầng dưới",
            "Mô hình MVC gồm đúng 3 thành phần trong khi đó số lượng thành phần theo mô hình phân tầng thay đổi tuỳ theo từng phần mềm",
        ],
        correctAnswer: 1,
        explanation: "True"
    },
    {
        id: 18,
        question: "Hãy chỉ ra các ý đúng cho kiểm thử hộp đen và kiểm thử hộp trắng??",
        options: [
            "Kiểm thử hộp trắng là phương pháp kiểm thử mà người kiểm thử cần quyền truy cập và cần hiểu mã nguồn để thực hiện các bài kiểm thử",
            "Kiểm thử hộp đen là phương pháp kiểm thử không yêu cầu người kiểm thử phải biết mã nguồn của hệ thống. giúp kiểm thử tập trung vào chức năng và hành vi của phần mềm",
            "Kiểm thử hộp trắng chỉ cần dựa vào đặc tả để kiểm thử",
            "Kiểm thử hộp đen giúp xác định được nguyên nhân lỗi",
        ],
        correctAnswer: [0, 1],
        explanation: "True"
    },
    {
        id: 19,
        question: "Mức kiểm thử nào giúp kiểm thử được toàn bộ (dịch vu và ràng buộc) hệ thống?",
        options: [
            "Kiểm thử hồi quy",
            "Kiểm thử hệ thống (System testing)",
            "Kiểm thử chấp nhận (Acceptance testing)",
            "Kiểm thử đơn vị (Unit testing)",
            "Kiểm thử tích hợp (Integration testing)",
        ],
        correctAnswer: 1,
        explanation: "True"
    },
    {
        id: 20,
        question: "Hãy chỉ ra các hoạt động trong Quản lý chất lượng phần mềm?",
        options: [
            "Quality Control (Kiểm soát chất lượng)",
            "Quanlity Management (Quản lý chất lượng)",
            "Quality Planning (quản lý chất lượng)",
            "Quality Assurance (đảm bảo chất lượng)",
            "Quanlity testing (Kiểm thử chất lượng)",
        ],
        correctAnswer: [0, 2, 3],
        explanation: "True"
    },
    {
        id: 21,
        question: "Mục đích của việc chuẩn hóa dữ liệu là gì",
        options: [
            "Thêm các thuộc tính mới cho các bảng mã lập trình viên Cảm thấy cần thiết trong quá trình lập trình",
            "Loại bỏ các bất thường khi cập nhật cơ sở dữ liệu",
            "Không cần thực hiện chuẩn hóa dữ liệu, trong quá trình lập trình nhóm thấy cần bảng nào thì tạo thêm bảng đó",
            "Giảm thiểu dư thừa dữ liệu",
            "Giúp dữ liệu lưu trữ được nhiều hơn",
        ],
        correctAnswer: [1, 3],
        explanation: "True"
    },
    {
        id: 22,
        question: "Trong quản trị rủi ro, việc lượng hoá các yếu tố về xác suất xảy ra, mức độ tác động, thời điểm xảy ra của từng rủi ro có mục đích gì?",
        options: [
            "Không có mục đích cụ thể nào",
            "Để sắp thứ tự ưu tiên giữa các rủi ro",
            "Để tài liệu quản trị rủi ro dễ đọc hơn",
        ],
        correctAnswer: 1,
        explanation: "True"
    },
    {
        id: 23,
        question: "Quản lý dự án phần mềm liên quan đến những hoạt động để đảm bảo những điều nào sau đây?",
        options: [
            "Phần mềm Chỉ cần phù hợp với yêu cầu của lập trình viên",
            "Phần mềm phải được phân phối theo đúng lịch trình",
            "Phần mềm phải được phân phối đúng hạn",
            "Phần mềm phải phù hợp với những yêu cầu của khách hàng và công ty phát triển",
        ],
        correctAnswer: [1, 2, 3],
        explanation: "True"
    },
    {
        id: 24,
        question: "Các thuật ngữ tiếng Anh nào sau đây xuất hiện trong Mô hình Scrum?",
        options: [
            "User Story",
            "Waterfall Model",
            "Scrum Master",
            "Sprint",
            "Spiral Model",
            "Product Owner",
            "Product Backlog",
            "Sprint Backlog",
        ],
        correctAnswer: [0, 2, 3, 6, 7, 5],
        explanation: "True"
    },
    {
        id: 25,
        question: "Đâu là những độ đo chung cho một chương trình phần mềm được phát triển bằng một ngôn ngữ lập trình bất kỳ?",
        options: [
            "Fan-in/Fan-out",
            "Số lượng phương thức bị ghi đè của lớp cha ở lớp con (NOM – Number Of Overrided Methods)",
            "Chiều dài mã nguồn (LOC - Line Of Code)",
            "Chiều dài định danh (LI – Length of identifiers)",
            "Độ sâu của cây kế thừa (DIT – Depth of Inheritance Tree)",
            "Số lượng lớp con trực tiếp (NOC – Number of Children)",
            "Độ phức tạp chu trình (CC - Cyclomatic complexity)",

        ],
        correctAnswer: [0, 2, 3, 6],
        explanation: "True"
    },
    {
        id: 26,
        question: "Để xây dựng các biểu đồ như: Biểu đồ phân rã chức năng (FDD - Function Decomposition Diagram), Biểu đồ luồng dữ liệu (DFD - DataFlow Diagram), Biểu đồ quan hệ thực thể (ERD - Entity Relationship Diagram), Biểu đồ ca sử dụng (Use-case Diagram), Biểu đồ trình tự (Sequence Diagram), nhóm phát triển phần mềm phải căn cứ vào đâu?",
        options: [
            "Dựa vào quan điểm của trưởng nhóm phát triển",
            "Dựa vào ý kiến chủ quan của nhóm lập trình",
            "Dựa vào yêu cầu phần mềm của khách hàng",

        ],
        correctAnswer: 2,
        explanation: "True"
    },
    {
        id: 27,
        question: "Phát biểu nào sau đây là đúng nhất về CASE??",
        options: [
            "Hệ thống gỡ rối tương tác",
            "Hệ thống quản lý phiên bản, công cụ xây dựng hệ thống",
            "Các hệ thống phần mềm hỗ trợ cho quá trình phát triển và tiến hóa phần mềm",
            "Trình tạo giao diện đồ họa cho việc xây dựng giao diện người dùng",
        ],
        correctAnswer: 2,
        explanation: "True"
    },
    {
        id: 28,
        question: "Quản lý dự án phần mềm liên quan đến những hoạt động để đảm bảo những điều nào sau đây?",
        options: [
            "Phần mềm phải phù hợp với những yêu cầu của khách hàng và công ty phát triển",
            "Phần mềm phải được phân phối theo đúng lịch trình",
            "Phần mềm Chỉ cần phù hợp với yêu cầu của lập trình viên",
            "Phần mềm phải được phân phối đúng hạn",
        ],
        correctAnswer: [0, 1, 3],
        explanation: "True"
    },
    {
        id: 29,
        question: "Những thành phần nào sau đây là cần thiết để phát triển được một phần mềm có chất lượng?",
        options: [
            "Môi trường",
            "Quy trình",
            "Công nghệ",
            "Con người.",
            "Biểu đồ",
        ],
        correctAnswer: [0, 1, 2, 3],
        explanation: "True"
    },
    {
        id: 30,
        question: "Những phát biểu nào sau đây có thể được coi là Yêu cầu phần mềm, KHÔNG PHẢI là Mục tiêu phần mềm??",
        options: [
            "Giao diện phần mềm nên dễ sử dụng, thân thiện với người dùng",
            "Khi lần đầu tiên thử nghiệm với người sử dụng, số lượng trung bình lỗi được tạo ra bởi người dùng kinh nghiệm sẽ không quá 2 lỗi một ngày Hệ thống phải có tính bảo mật và tối giản lỗi",
            "Mật khẩu đăng nhập phải có ít nhất 8 ký tự, có chữ, số và kỹ tự đặc biệt",
            "Hệ thống phải có tính bảo mật và tối giản lỗi.",
            "Người dùng có kinh nghiệm có thể sử dụng tất cả chức năng hệ thống sau 2 giờ huấn luyện",
        ],
        correctAnswer: [1, 2, 4],
        explanation: "True"
    },
    {
        id: 32,
        question: "Những phát biểu nào sau đây có thể được coi là Yêu cầu phần mềm, KHÔNG PHẢI là Mục tiêu phần mềm??",
        options: [
            "Hệ thống nên dễ sử dụng cho những người dùng kinh nghiệm và nên được tổ chức theo cách sao cho những lỗi người dùng được tối giản hóa",
            "Người dùng có kinh nghiệm có thể sử dụng tất cả chức năng hệ thống sau 2 giờ huấn luyện",
            "Mật khẩu đăng nhập phải có độ dài từ 4-8 ký tự, phải chứa ít nhất một ký tự đặc biệt",
            "Giao diện phần mềm nên dễ sử dụng, thân thiện với người dùng.",
            "Sau thời gian huấn luyện, số lượng trung bình lỗi được tạo ra bởi người dùng kinh nghiệm sẽ không quá 2 lỗi một ngày.",
        ],
        correctAnswer: [1, 2, 4],
        explanation: "True"
    },
    {
        id: 34,
        question: "Những thành phần nào sau đây là cần thiết để phát triển được một phần mềm có chất lượng??",
        options: [
            "Âm nhạc",
            "Thể thao",
            "Con người",
            "Quy trình",
            "Công nghệ",
        ],
        correctAnswer: [2, 3, 4],
        explanation: "True"
    },
    {
        id: 35,
        question: "Tài liệu kế hoạch dự án phần mềm đề cập đến những vấn đề nào sau đây?",
        options: [
            "Lịch trình công việc",
            "Sự phân chia công việc cho các thành viên trong dự án",
            "Phân tích rủi ro",
            "Cú pháp của ngôn ngữ lập trình sẽ được sử dụng",
            "Các nguồn lực có sẵn cho dự án",
        ],
        correctAnswer: [0, 1, 2, 4],
        explanation: "True"
    },
    {
        id: 36,
        question: "Những phát biểu nào sau đây là ĐÚNG về mô hình TDD (Test-Driven Development)?",
        options: [
            "Ưu điểm của mô hình này là: mã nguồn được thêm vào chỉ vừa đủ để chạy thành công kịch bản kiểm thử, hạn chế dư thừa và qua đó hạn chế khả năng xảy ra lỗi trên những phần dư thừa",
            "Đây là mô hình lập quy trình",
            "Trong mô hình này, việc thực thi các ca kiểm thử luôn được thực hiện TRƯỚC khi viết mã nguồn cho một tính năng mới",
            "Trong mô hình này, việc thực thi các ca kiểm thử luôn được thực hiện SAU khi viết mã nguồn cho một tính năng mới",
        ],
        correctAnswer: [0, 2],
        explanation: "True"
    },
    {
        id: 37,
        question: "Những phát biểu nào sau đây là đúng về các mức độ trong Kiểm thử phần mềm?",
        options: [
            "Kiểm thử đơn vị nhằm kiểm tra các nhóm thành phần được tích hợp lại để tạo ra một hệ thống hoặc một hệ thống con",
            "Kiểm thử hệ thống là trách nhiệm của một nhóm kiểm thử độc lập, các bài kiểm thử được dựa trên đặc tả phần mềm",
            "Kiểm thử đơn vị thường là trách nhiệm của lập trình viên, để kiểm tra các thành phần riêng lẻ, độc lập",
            "Kiểm thử hệ thống nhằm kiểm tra từng thành phần riêng lẻ của chương trình",
        ],
        correctAnswer: [1, 2],
        explanation: "True"
    },
    {
        id: 38,
        question: "Những vai trò nào sau đây xuất hiện trong Công nghệ Phần mềm??",
        options: [
            "Kiểm thử viên (Tester)",
            "Giảng viên (Lecturer)",
            "Thiết kế viên (Designer)",
            "Nhà quản lý (Manager)",
            "Người dùng cuối (End User)",
            "Sinh viên (Student)",
            "Nhân viên bảo trì (Maintenance staff)",
            "Lập trình viên (Developer)",
            "Khách hàng (Client)",
        ],
        correctAnswer: [0, 2, 3, 4, 6, 5, 7],
        explanation: "True"
    },
    {
        id: 39,
        question: "Những phát biểu nào sau đây là đúng về Mô hình thác nước??",
        options: [
            "Với Mô hình thác nước, một giai đoạn phải được hoàn thành trước khi chuyển sang giai đoạn tiếp theo",
            "Mô hình thác nước thích hợp với những dự án có yêu cầu thay đổi thường xuyên",
            "Đây là một mô hình theo kiểu hướng tài liệu",
            "Với Mô hình thác nước, nhóm phát triển BẮT BUỘC phải tương tác thường xuyên với khách hàng",
            "Mô hình thác nước thích hợp với những dự án có yêu cầu được hiểu rõ từ giai đoạn đầu và giới hạn những thay đổi trong quá trình thiết kế",
            "Mô hình thác nước khó khăn trong việc thích ứng với thay đổi yêu cầu của khách hàng sau khi quy trình đã được tiến hành",
        ],
        correctAnswer: [2, 5, 4, 0],
        explanation: "True"
    },
    {
        id: 41,
        question: "Các mối liên hệ giữa các lớp trong sơ đồ lớp được hỗ trợ bởi UML là gì?",
        options: [
            "Sở hữu chặt (Composition) hoặc Toàn bộ - bộ phận chặt",
            "Sở hữu lỏng (Aggregation) hoặc Toàn bộ - bộ phận lỏng",
            "Phụ thuộc (Dependency)",
            "Hiện thực hoá (Realization)",
            "Kế thừa (Generalization) hoặc Tổng quát hoá",
            "Mở rộng (Extend)",
            "Liên kết (Association)",
            "Bao gồm (Include)",
        ],
        correctAnswer: [0, 1, 2, 3, 4, 6],
        explanation: "True"
    },
    {
        id: 42,
        question: "Những phát biểu nào sau đây là đúng liên quan đến những lý do của việc dự án phát triển phần mềm thất bại??",
        options: [
            "Các thành viên trong nhóm phát triển dự án phần mềm mâu thuẫn với nhau",
            "Các thành viên trong nhóm phát triển tuân thủ lịch trình đề ra",
            "Người quản lý đề ra những yêu cầu, mong muốn không thực tế, trong khi người phát triển không phản hồi để sửa chữa chúng",
            "Người quản lý ước lượng thấp thời gian, chi phí và công sức cho việc phát triển dự án phần mềm",
            "Khách hàng thay đổi yêu cầu quan trọng khi dự án sắp kết thúc",
        ],
        correctAnswer: [0, 2, 3, 4],
        explanation: "True"
    },
    {
        id: 43,
        question: "Những phát biểu nào sau đây là đúng liên quan đến Kiểm thử hộp đen và Kiểm thử hộp trắng?",
        options: [
            "Kiểm thử hộp đen chỉ dựa trên đặc tả phần mềm, kiểm thử viên không cần có kiến thức về việc cài đặt phần mềm",
            "Kiểm thử phát hành, trong đó kiểm tra việc phát hành của một phần mềm sẽ được phân phối cho khách hàng, thường là kiểm thử hộp đen",
            "Kiểm thử phát hành, trong đó kiểm tra việc phát hành của một phần mềm sẽ được phân phối cho khách hàng, thường là kiểm thử hộp trắng",
            "Các ca kiểm thử trong kiểm thử hộp trắng được thiết kế nhằm tìm hiểu cấu trúc bên trong của phần mềm",
        ],
        correctAnswer: [0, 1, 3],
        explanation: "True"
    },
    {
        id: 44,
        question: "Những phát biểu nào sau đây là đúng khi so sánh giữa Mô hình máy khách - máy chủ (Client - Server) và Mô hình mạng ngang hàng (P2P hay Peer to Peer) là gì?",
        options: [
            "Hiệu suất của hệ thống theo mô hình Client-Server sẽ TĂNG lên khi có càng nhiều client tham gia vào, ngược lại hiệu suất của mô hình P2P sẽ GIẢM đi khi có càng nhiều peer tham gia vào",
            "Trong mô hình P2P, vai trò của các thành phần tham gia không còn được phân biệt rõ ràng giống như mô hình Client-Server, tất cả các thành phần tham gia đều có vai trò giống nhau",
        ],
        correctAnswer: 1,
        explanation: "True"
    },
    {
        id: 45,
        question: "Những phát biểu nào dưới đây được coi là Yêu cầu phi chức năng?",
        options: [
            "Sau khi hệ thống khởi động lại, tất cả các chức năng phải được khôi phục trong vòng 5 phút",
            "Mô hình phát triển phần mềm được sử dụng trong dự án là Scrum",
            "Ngôn ngữ lập trình được sử dụng để phát triển phần mềm là Java",
            "Hiệu suất của chương trình phải được tối ưu nhất có thể",
            "Hệ thống không được tiết lộ bất kỳ thông tin về khách hàng ngoài tên và số tham chiếu của họ cho người vận hành hệ thống",
            "Giao diện phải thân thiện, dễ dùng với người dùng cuối",
        ],
        correctAnswer: [0, 1, 2, 4],
        explanation: "True"
    },
    {
        id: 46,
        question: "Những phát biểu nào sau đây là đúng về Mô hình phân phối gia tăng??",
        options: [
            "Mô hình này giúp giảm thiểu nguy cơ thất bại của toàn bộ dự án",
            "Thay vì phát triển phần mềm và phân phối hệ thống chỉ một lần duy nhất, quá trình phát triển và phân phối được chia ra thành nhiều vòng tăng dần, mỗi vòng sẽ phân phối một tập con các chức năng được yêu cầu",
            "Mô hình phân phối gia tăng thích hợp với các dự án có yêu cầu thay đổi thường xuyên",
            "Những chức năng hệ thống có độ ưu tiên cao nhất được phân phối trước tiên, và có xu hướng nhận được kiểm thử nhiều nhất",
        ],
        correctAnswer: [0, 1, 3],
        explanation: "True"
    },
    {
        id: 48,
        question: "Những sự khác nhau giữa Mô hình thác nước (Waterfall) và Mô hình Scrum là gì?",
        options: [
            "Mô hình thác nước xử lý TOÀN BỘ yêu cầu trong CHỉ một vòng phát triển, trong khi đó Mô hình Scrum xử lý từng phần yêu cầu nhỏ (trích trong tập yêu cầu lớn) trong mỗi vòng phát triển",
            "Với Mô hình thác nước, các vai trò, nhiệm vụ của từng thành viên KHÔNG được phân biệt rõ ràng, trong khi đó, với Mô hình Scrum, các vai trò, nhiệm vụ của từng thành viên được phân định rõ ràng",
            "Mô hình thác nước KHÔNG cần tương tác với khách hàng thường xuyên, trong khi đó Mô hình Scrum cần phải tương tác thường xuyên với khách hàng",
        ],
        correctAnswer: [0, 2],
        explanation: "True"
    },
    {
        id: 5,
        question: "Chỉ ra đâu là mối quan hệ giữa Tổng thể - bộ phận lỏng trong các mối quan hệ giữa các lớp đối tượng ?",
        options: [
            "Quan hệ liên kết (Association)",
            "Quan hệ phụ thuộc (Dependency)",
            "Quan hệ kết hợp (Composition)",
            "Quan hệ tập hợp (Aggregation)",
            "Quan hệ hiện thực hóa (Realization)",
            "Quan hệ kế thừa/tổng quát hóa (Generalization)",

        ],
        correctAnswer: 3,
        explanation: "True"
    },
    {
        id: 5,
        question: "Những phát biểu nào sau đây là đúng về Mô hình phân phối gia tăng?",
        options: [
            "Những chức năng có độ ưu tiên cao nhất được phát triển và phân phối trước, và do đó có xu hướng nhận được kiểm thử nhiều hơn những chức năng có độ ưu tiên thấp",
            "Mô hình phân phối gia tăng thích hợp với các dự án có yêu cầu thay đổi thường xuyên trong quá trình phát triển",
            "Mô hình phân phối gia tăng thích hợp với những dự án có yêu cầu KHÔNG cần rõ ràng ngay từ đầu",
            "Trong mô hình này, quá trình phát triển và phân phối được chia ra thành nhiều vòng, mỗi vòng sẽ phát triển và phân phối một tập con các chức năng được yêu cầu",
        ],
        correctAnswer: 3,
        explanation: "True"
    },
    {
        id: 5,
        question: "Khi thiết kế giao diện phần mềm, thiết kế viên phải xem xét những yếu tố con người nào sau đây?",
        options: [
            "Thiết kế viên cảm thấy giao diện phù hợp là được, không cần quan tâm đến các yếu tố khác",
            "Lượng thông tin mà người dùng có thể ghi nhớ trong một thời điểm là giới hạn",
            "Cách tương tác và sở thích của mỗi người dùng là khác nhau",
            "Người dùng dễ mắc sai lầm khi tương tác với phần mềm mới",
        ],
        correctAnswer: 3,
        explanation: "True"
    },
    {
        id: 5,
        question: "Những phát biểu nào sau đây là đúng về các mức độ Kiểm thử phần mềm ??",
        options: [
            "Kiểm thử hệ thống nhằm kiểm tra tất cả khía cạnh của toàn bộ hệ thống (như chức năng, khả năng sử dụng, độ tin cậy, hiệu suất, tính khả chuyển,..)",
            "Kiểm thử tích hợp nhằm kiểm tra các đơn vị khi kết hợp lại với nhau",
            "Kiểm thử đơn vị nhằm kiểm tra các đơn vị riêng lẻ một cách độc lập",
            "Kiểm thử chấp nhận là trách nhiệm của chi riêng nhóm phát triển, không liên quan đến khách hàng",
        ],
        correctAnswer: 3,
        explanation: "True"
    },
    {
        id: 5,
        question: "Đâu là những nguyên nhân dẫn đến hoạt động Bảo trì phần mềm ???",
        options: [
            "Hiệu suất và độ tin cậy của phần mềm vẫn đáp ứng được yêu cầu của khách hàng",
            "Phần mềm cần chuyển sang hoạt động ở môi trường khác (ví dụ: trên hệ điều hành khác) hoặc cần phải làm việc với những thiết bị mới",
            "Nhiều lỗi phát sinh, cần được sửa chữa, khi sử dụng phần mềm",
            "Khách hàng có thêm yêu cầu mới khi sử dụng phần mềm",
        ],
        correctAnswer: 3,
        explanation: "True"
    },
    {
        id: 5,
        question: "Hoạt động Quản lý dự án phần mềm nhằm đảm bảo những điều nào sau đây ???",
        options: [
            "Phần mềm được phân phối đúng thời gian",
            "Phần mềm được phát triển theo đúng lịch trình",
            "Phần mềm phù hợp với những yêu cầu chức năng và chất lượng của khách hàng, cũng như của nhóm phát triển",
            "Phần mềm CHỉ phù hợp với yêu cầu chủ quan của lập trình viên",
            "Phần mềm được phân phối theo đúng ngân sách",
        ],
        correctAnswer: 3,
        explanation: "True"
    },
    {
        id: 5,
        question: "Phát biểu nào sau đây là đúng về sự khác nhau giữa Mô hình Thác nước và Mô hình Scrum ????",
        options: [
            "Với mô hình thác nước, các vai trò, nhiệm vụ của từng thành viên KHÔNG được phân biệt rõ ràng, trong khi đó, với mô hình Scrum, các vai trò, nhiệm vụ của từng thành viên được quy định rõ ràng",
            "Với mô hình Scrum, nhóm phát triển sẽ phát triển TOÀN BỘ yêu cầu trong CHỈ một vòng phát triển, trong khi đó với mô hình thác nước, nhóm phát triển sẽ phát triển từng phần nhỏ của yêu cầu phần mềm(được lấy từ tập danh sách yêu cầu ban đầu) trong mỗi vòng phát triển",
            "Với mô hình thác nước, nhóm phát triển KHÔNG cần tương tác với khách hàng thường xuyên, trong khi đó với mô hình Scrum, nhóm phát triển cần phải tương tác thường xuyên với khách hàng",

        ],
        correctAnswer: 3,
        explanation: "True"
    },
    {
        id: 5,
        question: "Những phát biểu nào sau đây có thể được coi là Yêu cầu phần mềm, KHÔNG PHẢI là Mục tiêu phần mềm ??",
        options: [
            "Khi việc đăng ký thuê đã hoàn thành, khách hàng sẽ nhận được email nhắc nhở về thời gian khởi hành trước 72h, 48h và 24h",
            "Hệ thống phải đáp ứng được càng nhiều càng tốt lượt truy cập trong một thời điểm",
            "Phần mềm phải tối giản hoá số lỗi phát sinh",
            "Sau khi hệ thống đưa vào vận hành, cứ 1 tuần, dữ liệu phải được sao lưu một lần",
            "Phần mềm phải được phát triển sử dụng ngôn ngữ lập trình Java",
            "Giao diện chương trình phải dễ sử dụng, thân thiện với người dùng",
            "Khách hàng có thể sửa đổi hoặc huỷ bỏ việc đăng ký thuê xe bằng cách truy vấn hợp đồng của họ trên hệ thống trung tâm sử dụng mã hợp đồng và tên của họ",
        ],
        correctAnswer: 3,
        explanation: "True"
    },
    {
        id: 5,
        question: "Các sản phẩm (work products) thường được tạo ra trong quá trình phát triển phần mềm là gì ???",
        options: [
            "Báo cáo kiểm thử",
            "Tài liệu đặc tả yêu cầu",
            "Tài liệu vận hành, bảo trì",
            "Tài liệu giảng dạy",
            "Tài liệu thiết kế",
            "Nguyên mẫu giao diện",
            "Mã nguồn / Chương trình máy tính",
        ],
        correctAnswer: 3,
        explanation: "True"
    },
    {
        id: 5,
        question: "Phát biểu nào sau đây là đúng về các mức độ trưởng thành trong mô hình CMMi ??",
        options: [
            "Mô hình CMMi có 5 mức độ trưởng thành, mỗi mức độ trưởng thành bao gồm một số KPA (Key Process Area) nhất định",
            "Cứ sau một khoảng thời gian nhất định, mức độ trưởng thành của một doanh nghiệp sẽ tự động tăng lên",
            "Trong mô hình CMMi, số lượng KPA (Key Process Area) của mỗi mức độ trưởng thành là giống nhau",
        ],
        correctAnswer: 3,
        explanation: "True"
    },
    {
        id: 5,
        question: "Trong quản trị rủi ro, việc lượng hoá các yếu tố về xác suất xảy ra, mức độ tác động, hay thời điểm xảy ra của các rủi ro có mục đích gì ???",
        options: [
            "Để sắp thứ tự ưu tiên cho các rủi ro",
            "Để tài liệu quản trị rủi ro dễ đọc hơn",
            "Để đưa việc đánh giá các rủi ro theo các yếu tố này về cùng một khoảng giá trị",
            "Không có mục đích cụ thể nào",
        ],
        correctAnswer: 3,
        explanation: "True"
    },
    {
        id: 5,
        question: "Những phát biểu nào sau đây là đúng về mục tiêu của Kiểm thử phần mềm ? ???",
        options: [
            "Kiểm thử khiếm khuyết (Defect testing) để phát hiện lỗi hoặc khuyết tật trong phần mềm có hành xử không đúng hoặc không phù hợp với đặc tả của nó",
            "Kiểm thử xác thực (Validation testing) để chứng minh cho người phát triển và khách hàng thấy rằng phần mềm đáp ứng các yêu cầu của nó",
            "Một ca kiểm thử xác thực thành công là một thử nghiệm khiến cho hệ thống thực hiện không đúng và bộc lộ lỗi",
            "Một ca kiểm thử khiếm khuyết thành công là một thử nghiệm cho thấy hệ thống hoạt động giống như đặc tả yêu cầu của nó",
        ],
        correctAnswer: 3,
        explanation: "True"
    },
    {
        id: 5,
        question: "Các hoạt động lõi, thường xuất hiện, trong Công nghệ phần mềm là gì?",
        options: [
            "Lập kế hoạch dự án",
            "Lập trình",
            "Vận hành & bảo trì",
            "Phân tích, đặc tả yêu cầu phần mềm",
            "Học tập",
            "Thiết kế phần mềm",
            "Kiểm thử",
            "Giảng dạy",
        ],
        correctAnswer: 3,
        explanation: "True"
    },
    {
        id: 5,
        question: "Tài liệu kế hoạch dự án phần mềm đề cập đến những vấn đề nào sau đây ??",
        options: [
            "Bảng phân chia công việc",
            "Thiết kế giao diện người dùng",
            "Cú pháp của ngôn ngữ lập trình sẽ được sử dụng",
            "Danh sách các ca kiểm thử cần thực hiện",
            "Phân tích rủi ro",
            "Các nguồn lực có sẵn cho dự án",
            "Lịch trình công việc",
        ],
        correctAnswer: 3,
        explanation: "True"
    },
    {
        id: 5,
        question: "Những vai trò điển hình nào sau đây xuất hiện trong Công nghệ Phần mềm ???",
        options: [
            "Giảng viên (Lecturer)",
            "Nhân viên bảo trì (Maintenance Staff)",
            "Thiết kế viên (Designer)",
            "Khách hàng (Customer/Client)",
            "Chuyên viên phân tích nghiệp vụ phần mềm (Business Analyst)",
            "Kiểm thử viên (Tester)",
            "Kỹ sư đảm bảo chất lượng (QA Engineer)",
            "Nhà quản lý dự án (Project Manager)",
            "Người dùng cuối (End User)",
            "Kiến trúc sư hệ thống (System Architect)",
            "Sinh viên (Student)",
            "Chuyên gia lĩnh vực miền (Domain Specialist)",
            "Lập trình viên (Developer)",
        ],
        correctAnswer: 3,
        explanation: "True"
    },
]







