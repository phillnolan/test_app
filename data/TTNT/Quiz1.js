export const sampleQuestions = [
    {
        id: 0,
        question: "Có bao nhiêu qui tắc trong giải thuật tìm kiếm theo chiều rộng?",
        options: [
            "1",
            "2",
            "3",
            "4"
        ],
        correctAnswer: 3 - 1,
        explanation: true
    },
    {
        id: 1,
        question: "Giải thuật tìm kiếm theo chiều rộng bắt đầu duyệt từ?",
        options: [
            "Nút kề.",
            "Nút gốc.",
            "Nút con.",
            "Nút cha."
        ],
        correctAnswer: 2 - 1,
        explanation: true
    },
    {
        id: 2,
        question: "\"Nếu không tìm thấy đỉnh liền kề, thì xóa đỉnh đầu tiên trong hàng đợi.\" là qui tắc thứ mấy trong giải thuật tìm kiếm theo chiều rộng?",
        options: [
            "Qui tắc 2.",
            "Qui tắc 4.",
            "Qui tắc 1.",
            "Qui tắc 3."
        ],
        correctAnswer: 1 - 1,
        explanation: true
    },
    {
        id: 3,
        question: "Đâu không phải là ứng dụng của giải thuật tìm kiếm theo chiều rộng trong bài toán lý thuyết đồ thị?",
        options: [
            "Tìm đường đi ngắn nhất giữa 2 đỉnh u và v.",
            "Tìm các thành phần liên thông.",
            "Tìm tất cả các đỉnh trong một thành phần liên thông.",
            "Tìm kiếm có giới hạn."
        ],
        correctAnswer: 4 - 1,
        explanation: true
    },
    {
        id: 4,
        question: "Nếu số đỉnh là hữu hạn thì giải thuật tìm kiếm theo chiều rộng có tìm ra kết quả không?",
        options: [
            "Có",
            "Không",
            "Cả A và B đều đúng",
            "Cả A và B đều sai",
        ],
        correctAnswer: 1 - 1,
        explanation: true
    },
    {
        id: 5,
        question: "Giải thuật tìm kiếm theo chiều rộng có bao nhiều tính chất?",
        options: [
            "3 tính chất.",
            "1 tính chất.",
            "4 tính chất.",
            "2 tính chất."
        ],
        correctAnswer: 4 - 1,
        explanation: true
    },
    {
        id: 6,
        question: "Giải thuật tìm kiếm theo chiều rộng có tính chất vét cạn vậy có nên áp dụng vào đồ thị có số đỉnh lớn không?",
        options: [
            "Nên",
            "Không nên",
            "Cả A và B đều đúng.",
            "Cả A và B đều sai"
        ],
        correctAnswer: 2 - 1,
        explanation: true
    },
    {
        id: 7,
        question: "Đáp án nào đúng với giải thuật tìm kiếm theo chiều rộng?",
        options: [
            "Duyệt tất cả các đỉnh.",
            "Duyệt một nửa số đỉnh.",
            "Chỉ duyệt đỉnh đầu của đồ thị.",
            "Chỉ duyệt đỉnh cuối của đồ thị"
        ],
        correctAnswer: 1 - 1,
        explanation: true
    },
    {
        id: 8,
        question: "Đáp án nào đúng với giải thuật tìm kiếm theo chiều rộng?",
        options: [
            "Sử dụng hàng đợi.",
            "Sử dụng ngăn xếp.",
            "Sử dụng mảng nhiều chiều.",
            "Sử dụng ma trận."
        ],
        correctAnswer: 1 - 1,
        explanation: true
    },
    {
        id: 100,
        question: "Đáp án nào đúng với giải thuật tìm kiếm theo chiều sâu?",
        options: [
            "Sử dụng hàng đợi.",
            "Sử dụng ngăn xếp.",
            "Sử dụng mảng nhiều chiều.",
            "Sử dụng ma trận."
        ],
        correctAnswer: 2 - 1,
        explanation: true
    },
    {
        id: 9,
        question: "Có bao nhiêu qui tắc trong giải thuật tìm kiếm theo chiều sâu?",
        options: [
            "1",
            "2",
            "3",
            "4"
        ],
        correctAnswer: 3 - 1,
        explanation: true
    },
    {
        id: 10,
        question: "Tìm kiếm theo chiều sâu có giới hạn là gì?",
        options: [
            "Là một thuật toán phát triển các nút đã xét các theo chiều sâu nhưng có giới hạn mức.",
            "Là một thuật toán phát triển các nút chưa xét các theo chiều sâu nhưng có giới hạn mức.",
            "Là một thuật toán phát triển tất cả các nút theo chiều sâu nhưng có giới hạn mức.",
            "Là một thuật toán phát triển các nút chưa xét các theo chiều rộng nhưng có giới hạn mức."
        ],
        correctAnswer: 2 - 1,
        explanation: true
    },
    {
        id: 11,
        question: "Giải thuật tìm kiếm sâu dần có sử dụng không gian tuyến tính O (bxL) không?",
        options: [
            "Không.",
            "Có",
            "Cả A và B đều đúng.",
            "Cả A và B đều sai"
        ],
        correctAnswer: 2 - 1,
        explanation: true
    },
    {
        id: 12,
        question: "Tìm kiếm theo giá thành thống nhất là tối ưu vì:",
        options: [
            "Con đường có chi phí cao nhất được chọn.",
            "Con đường có chi phí thấp nhất được chọn.",
            "Con đường có chi phí cao nhất và thấp nhất được chọn.",
            "Con đường có chi phí thấp nhất không được chọn."
        ],
        correctAnswer: 2 - 1,
        explanation: true
    },
    {
        id: 13,
        question: "Đâu là nhược điểm của giải thuật tìm kiếm theo giá thành thống nhất?",
        options: [
            "Không cần quan tâm đến số lượng các bước liên quan đến tìm kiếm và chỉ quan tâm đến chi phí đường dẫn.",
            "Quan tâm đến số lượng các bước liên quan đến tìm kiếm và không quan tâm đến chi phí đường dẫn.",
            "Quan tâm đến số lượng các bước liên quan đến tìm kiếm và quan tâm đến chi phí đường dẫn.",
            "Không cần quan tâm đến số lượng các bước liên quan đến tìm kiếm và không quan tâm đến chi phí đường dẫn."
        ],
        correctAnswer: 1 - 1,
        explanation: true
    },
    {
        id: 14,
        question: "\"Không cần quan tâm đến số lượng các bước liên quan đến tìm kiếm và chỉ quan tâm đến chi phí đường dẫn\" do đó:",
        options: [
            "Giải thuật tìm kiếm theo giá thành thống nhất không thể bị mắt kẹt trong một vòng lặp vô hạn.",
            "Giải thuật tìm kiếm theo giá thành thống nhất có thể bị mắt kẹt trong một vòng lặp vô hạn.",
            "Cả A và B đều đúng.",
            "Cả A và B đều sai"
        ],
        correctAnswer: 2 - 1,
        explanation: true
    },
    {
        id: 15,
        question: "Thuật toán nào đưa ra để khắc phục điểm yếu của thuật toán tìm kiếm giới hạn độ sâu DLS?",
        options: [
            "Tìm kiếm theo chiều dài.",
            "Tìm kiếm theo chiều rộng.",
            "Tìm kiếm sâu dần.",
            "Tìm kiếm beam"
        ],
        correctAnswer: 3 - 1,
        explanation: true
    },
    {
        id: 16,
        question: "Giải thuật tìm kiếm sâu dần thường áp dụng cho bài toán nào?",
        options: [
            "Bài toán có không gian trạng thái lớn và độ sâu của nghiệm không biết trước.",
            "Bài toán có không gian trạng thái lớn và độ sâu của nghiệm biết trước.",
            "Bài toán có không gian trạng thái nhỏ và độ sâu của nghiệm không biết trước.",
            "Bài toán có không gian trạng thái nhỏ và độ sâu của nghiệm biết trước."
        ],
        correctAnswer: 1 - 1,
        explanation: true
    },
    {
        id: 17,
        question: "Hạn chế chính của giải thuật tìm kiếm sâu dần là gì?",
        options: [
            "Không lặp lại tất cả các công việc của giai đoạn trước.",
            "Lặp lại một nửa công việc của giai đoạn trước.",
            "Lặp lại tất cả các công việc của giai đoạn trước.",
            "Lặp lại tất cả các công việc của giai đoạn sau."
        ],
        correctAnswer: 3 - 1,
        explanation: true
    },
    {
        id: 18,
        question: "Trong giải thuật tìm kiếm leo đồi?",
        options: [
            "Khi phát triển một đỉnh u thì bước tiếp theo ta không chọn trong số các đỉnh con của u, đỉnh có hứa hẹn nhiều nhất để phát triển, đỉnh này được xác định bởi hàm đánh giá.",
            "Khi phát triển một đỉnh u thì bước tiếp theo ta chọn trong số các đỉnh con của u, đỉnh có hứa hẹn nhiều nhất để phát triển, đỉnh này được xác định bởi hàm đánh giá.",
            "Khi phát triển một đỉnh u thì bước tiếp theo ta chọn trong số các đỉnh con của u, đỉnh có hứa hẹn nhiều nhất để phát triển, đỉnh này không được xác định bởi hàm đánh giá.",
            "Khi phát triển một đỉnh u thì bước tiếp theo ta không chọn trong số các đỉnh con của u, đỉnh có hứa hẹn nhiều nhất để phát triển, đỉnh này không được xác định bởi hàm đánh giá."
        ],
        correctAnswer: 2 - 1,
        explanation: true
    },
    {
        id: 19,
        question: "Giải thuật tìm kiếm Simulated Annealing sử dụng chiến lược tìm kiếm gì?",
        options: [
            "Ngẫu nhiên.",
            "Tuần tự",
            "Không ngẫu nhiên",
            "Không tuần tự"
        ],
        correctAnswer: 1 - 1,
        explanation: true
    },
    {
        id: 20,
        question: "Đâu là đáp án đúng khi nói đến giải thuật Simulated Annealing?",
        options: [
            "Không thể đối phó với các mô hình phi tuyến tính cao, dữ liệu hỗn loạn và ồn ào và nhiều ràng buộc.",
            "Có thể đối phó với các mô hình phi tuyến tính thấp, dữ liệu hỗn loạn và ồn ào và nhiều ràng buộc.",
            "Không thể đối phó với các mô hình phi tuyến tính thấp, dữ liệu hỗn loạn và ồn ào và ít ràng buộc.",
            "Có thể đối phó với các mô hình phi tuyến tính cao, dữ liệu hỗn loạn và ồn ào và nhiều ràng buộc."
        ],
        correctAnswer: 4 - 1,
        explanation: true
    },
    {
        id: 21,
        question: "Trong giải thuật tìm kiểm beam?",
        options: [
            "Không phát triển một đỉnh K tốt nhất",
            "Phát triển nhiều đỉnh K tốt nhất",
            "Chỉ phát triển một đỉnh K tốt nhất",
            "Phát triển nhiều đỉnh K nhưng không tốt nhất"
        ],
        correctAnswer: 3 - 1,
        explanation: true
    },
    {
        id: 22,
        question: "Đâu là ưu điểm của giải thuật tìm kiếm beam?",
        options: [
            "Khả năng làm tăng tính toán.",
            "Khả năng làm giảm tính toán.",
            "Khả năng tiêu thụ nhiều bộ nhớ.",
            "Khả năng làm tăng tính toán và tiêu thụ nhiều bộ nhớ."
        ],
        correctAnswer: 2 - 1,
        explanation: true
    },
    {
        id: 23,
        question: "Đâu là nhược điểm của giải thuật tìm kiếm beam?",
        options: [
            "Có thể dẫn đến mục tiêu và thậm chí không đạt được mục tiêu.",
            "Có thể không dẫn đến mục tiêu và đạt được mục tiêu.",
            "Có thể dẫn đến mục tiêu và đạt được mục tiêu.",
            "Có thể không dẫn đến mục tiêu và thậm chí không đạt được mục tiêu."
        ],
        correctAnswer: 4 - 1,
        explanation: true
    },
    {
        id: 24,
        question: "Giải thuật tìm kiếm nhánh cận giải quyết các bài toán nào?",
        options: [
            "Các bài toán không tối ưu tổ hợp.",
            "Các bài toán tối ưu tổ hợp.",
            "Các bài toán tối ưu tổ hợp và các bài toán không tối ưu tổ hợp.",
            "Tất cả các bài toán."
        ],
        correctAnswer: 2 - 1,
        explanation: true
    },
    {
        id: 25,
        question: "Giải thuật tìm kiếm nhánh cận là một dạng của tiến của giải thuật nào?",
        options: [
            "Giải thuật quay lui.",
            "Giải thuật leo đồi.",
            "Giải thuật tham lam.",
            "Tất cả các ý trên"
        ],
        correctAnswer: 1 - 1,
        explanation: true
    },
    {
        id: 26,
        question: "Đâu là ưu điểm của giải thuật tìm kiếm nhánh cận?",
        options: [
            "Quét qua toàn bộ nghiệm có thể có của bài toán.",
            "Chỉ quét qua một nửa nghiệm có thể có của bài toán.",
            "Không quét qua toàn bộ nghiệm có thể có của bài toán.",
            "Quét qua toàn bộ nghiệm có thể không có của bài toán."
        ],
        correctAnswer: 3 - 1,
        explanation: true
    },
    {
        id: 27,
        question: "Giải thuật Minimax là gì?",
        options: [
            "Là một giải thuật đệ quy.",
            "Là một giải thuật không đệ quy.",
            "Là một giải thuật đệ quy và không đệ quy.",
            "Tất cả các đáp án đều sai."
        ],
        correctAnswer: 1 - 1,
        explanation: true
    },
    {
        id: 28,
        question: "Giải thuật Minimax thể hiện bằng cách định trị các Node trên cây trò chơi:\n• Node thuộc lớp MAX thì gán cho nó giá trị ........ nhất của con Node đó.\n• Node thuộc lớp MIN thì gán cho nó giá trị ........ nhất của con Node đó.\nĐiền vào chỗ trống.",
        options: [
            "Lớn - Lớn.",
            "Nhỏ – Nhỏ.",
            "Lớn – Lớn.",
            "Lớn – Nhỏ."
        ],
        correctAnswer: 4 - 1,
        explanation: true
    },
    {
        id: 29,
        question: "Giải thuật Minimax có tính chất gì?",
        options: [
            "Véc cạn.",
            "Rà soát.",
            "Cả A và B đều đúng.",
            "Cả A và B đều sai."
        ],
        correctAnswer: 1 - 1,
        explanation: true
    },
    {
        id: 30,
        question: "Duyệt hết các trạng thái nên giải thuật Minimax?",
        options: [
            "Tốn nhiều thời gian.",
            "Không tốn nhiều thời gian.",
            "Cả A và B đều đúng.",
            "Cả A và B đều sai."
        ],
        correctAnswer: 1 - 1,
        explanation: true
    },
    {
        id: 31,
        question: "Giải thuật nào sử dụng chung với thuật toán tìm kiếm Minimax nhằm hỗ trợ giảm bớt các không gian trạng thái?",
        options: [
            "Giải thuật tìm kiếm beam.",
            "Giải thuật tìm kiếm sâu dần.",
            "Giải thuật cắt tỉa Alpha-Beta.",
            "Tất cả các giải thuật trên."
        ],
        correctAnswer: 3 - 1,
        explanation: true
    },
    {
        id: 32,
        question: "Nguyên tắc đơn giản của giải thuật cắt tỉa Alpha-Beta là gì?",
        options: [
            "\"Nếu biết là trường hợp xấu thì cần phải xét thêm\".",
            "\"Nếu biết không phải trường hợp xấu thì không cần phải xét thêm\".",
            "\"Nếu biết không phải trường hợp xấu thì cần phải xét thêm\".",
            "\"Nếu biết là trường hợp xấu thì không cần phải xét thêm\"."
        ],
        correctAnswer: 4 - 1,
        explanation: true
    },
    {
        id: 33,
        question: "Sử dụng giải thuật nào để xác định được Alpha và Beta trong giải thuật cắt tỉa Alpha-Beta?",
        options: [
            "Giải thuật tìm kiếm beam.",
            "Giải thuật tìm kiếm theo chiều rộng.",
            "Giải thuật tìm kiếm theo chiều sâu.",
            "Tất cả các giải thuật trên."
        ],
        correctAnswer: 3 - 1,
        explanation: true
    },
    {
        id: 34,
        question: "Có mấy giải thuật dựa vào giải thuật tìm kiếm tốt nhất đầu tiên?",
        options: [
            "1.",
            "2.",
            "3.",
            "4."
        ],
        correctAnswer: 3 - 1,
        explanation: true
    },
    {
        id: 35,
        question: "Giải thuật nào dựa vào giải thuật tìm kiếm tốt nhất đầu tiên?",
        options: [
            "Giải thuật A*.",
            "Giải thuật leo đồi.",
            "Giải thuật tham lam.",
            "Giải thuật tìm kiếm nhánh cận."
        ],
        correctAnswer: 1 - 1,
        explanation: true
    },
    {
        id: 36,
        question: "Giải thuật tìm kiếm tốt nhất đầu tiên kết hợp 2 ưu điểm của 2 giải thuật nào?",
        options: [
            "Giải thuật tìm kiếm nhánh cận và giải thuật leo đồi.",
            "Giải thuật tìm kiếm beam và giải thuật tìm kiếm theo chiều rộng.",
            "Giải thuật leo đồi và giải thuật tham lam.",
            "Giải thuật tìm kiếm theo chiều sâu và giải thuật tìm kiếm theo chiều rộng."
        ],
        correctAnswer: 4 - 1,
        explanation: true
    },
    {
        id: 37,
        question: "Đâu là đáp án đúng khi nói về giải thuật tìm kiếm tốt nhất đầu tiên?",
        options: [
            "Giải thuật tìm kiếm tốt nhất đầu tiên có thể bị kẹt trong một vòng lặp như A*.",
            "Giải thuật tìm kiếm tốt nhất đầu tiên không thể bị kẹt trong một vòng lặp như DFS.",
            "Giải thuật tìm kiếm tốt nhất đầu tiên có thể bị kẹt trong một vòng lặp như DFS.",
            "Tất cả các đáp án đều sai."
        ],
        correctAnswer: 3 - 1,
        explanation: true
    },
    {
        id: 38,
        question: "Đâu là đán án đúng khi nói về giải thuật tham lam?",
        options: [
            "Giải thuật này tối ưu để tìm giải pháp toàn cục.",
            "Giải thuật này không tối ưu để tìm giải pháp toàn cục.",
            "Tất cả các đáp án đều đúng.",
            "Tất cả các đáp án đều sai."
        ],
        correctAnswer: 2 - 1,
        explanation: true
    },
    {
        id: 39,
        question: "Lựa chọn của giải thuật tham lam?",
        options: [
            "Có thể phụ thuộc vào lựa chọn trước đó.",
            "Không phụ thuộc vào lựa chọn trước đó.",
            "Chắc chắn phụ thuộc vào lựa chọn trước đó.",
            "Tất cả đáp án đều sai."
        ],
        correctAnswer: 1 - 1,
        explanation: true
    },
    {
        id: 40,
        question: "Đâu là đáp án đúng khi nói về giải thuật tham lam?",
        options: [
            "Tối ưu để tìm giải pháp toàn cục.",
            "Không tối ưu để tìm giải pháp toàn cục.",
            "Tất cả các đáp án đều đúng.",
            "Tất cả các đáp án đều sai."
        ],
        correctAnswer: 2 - 1,
        explanation: true
    },
    {
        id: 41,
        question: "Giải thuật A* được công bố đầu tiên vào năm nào?",
        options: [
            "1966.",
            "1967.",
            "1968.",
            "1969."
        ],
        correctAnswer: 3 - 1,
        explanation: true
    },
    {
        id: 42,
        question: "Đâu là đáp án đúng khi nói về giải thuật A*?",
        options: [
            "Không tốn nhiều bộ nhớ để lưu lại những trạng thái đã đi qua.",
            "Tốn khá nhiều bộ nhớ để lưu lại những trạng thái đã đi qua.",
            "Không tốn bộ nhớ để lưu lại những trạng thái đã đi qua.",
            "Tất cả đều sai.",
        ],
        correctAnswer: 2 - 1,
        explanation: true
    },
    {
        id: 43,
        question: "Giải thuật tìm kiếm truyền lùi (back tracking) bắt đầu tại trạng thái?",
        options: [
            "Ban đầu bài toán.",
            "Giữa bài toán",
            "Cuối bài toán.",
            "Tất cả đáp án đề sai."
        ],
        correctAnswer: 1 - 1,
        explanation: true
    },
    {
        id: 44,
        question: "Thông tin luật đánh giá heuristic về bài toán được biểu diễn bằng luật điều khiển dưới dạng gì?",
        options: [
            "For.",
            "Loop.",
            "While.",
            "If Then"
        ],
        correctAnswer: 4 - 1,
        explanation: true
    },
    {
        id: 45,
        question: "Sử dụng thuật giải heuristic thường?",
        options: [
            "Lâu và khó đưa ra kết quả do vậy, chi phí thấp.",
            "Lâu và khó đưa ra kết quả do vậy, chi phí cao.",
            "Nhanh chóng và dễ dàng đưa ra kết quả do vậy, chi phí thấp.",
            "Nhanh chóng và dễ dàng đưa ra kết quả do vậy, chi phí cao."
        ],
        correctAnswer: 3 - 1,
        explanation: true
    },
    {
        id: 46,
        question: "Giải thuật heuristic thường thể hiện?",
        options: [
            "Khá tự nhiên, gần gũi với cách suy nghĩ và hành động của con người.",
            "Không tự nhiên, khó gần gũi với cách suy nghĩ và hành động của con người.",
            "Không tự nhiên, khó gần gũi với cách suy nghĩ và hành động của máy tính.",
            "Khá tự nhiên, gần gũi với cách suy nghĩ và hành động của máy tính."
        ],
        correctAnswer: 1 - 1,
        explanation: true
    },
    {
        id: 47,
        question: "Đâu là đáp án đúng khi nói đến giải thuật đồ thị và-hoặc?",
        options: [
            "Giải thuật sử dụng nhiều hàm ước lượng heuristic để đánh giá trạng thái trong đồ thị.",
            "Giải thuật sử dụng chỉ một hàm ước lượng heuristic để đánh giá mỗi trạng thái trong đồ thị.",
            "Giải thuật sử không sử dụng hàm ước lượng heuristic để đánh giá mỗi trạng thái trong đồ thị.",
            "Giải thuật sử dụng ít hàm ước lượng heuristic để đánh giá mỗi trạng thái trong đồ thị."
        ],
        correctAnswer: 2 - 1,
        explanation: true
    },
    {
        id: 48,
        question: "Đâu là đáp án đúng khi nói đến giải thuật đồ thị và-hoặc?",
        options: [
            "Giải thuật sử dụng một danh sách S nhằm mục đích cho quá trình truyền lùi về gốc của đồ thị.",
            "Giải thuật không sử dụng một danh sách S nhằm mục đích cho quá trình truyền lùi về gốc của đồ thị.",
            "Giải thuật sử dụng một danh sách S nhằm mục đích cho quá trình truyền lùi về đỉnh con của đồ thị.",
            "Tất cả đáp án đều sai."
        ],
        correctAnswer: 1 - 1,
        explanation: true
    },
    {
        id: 49,
        question: "Đâu không phải là đặc trưng cơ bản của hệ chuyên gia?",
        options: [
            "Sử dụng tri thức chuyên gia",
            "Sử dụng kỹ thuật tìm kiếm",
            "Không sử dụng thông tin Heuristics",
            "Có khả năng xử lý ký hiệu"
        ],
        correctAnswer: 3 - 1,
        explanation: true
    },

]