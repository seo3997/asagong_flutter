import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/service/app_service.dart';

class AdQnaWriteScreen extends StatefulWidget {
  final int productId;
  final String? qnaId;
  final String? title;
  final String? contents;
  final String? secretYn;

  const AdQnaWriteScreen({
    super.key,
    required this.productId,
    this.qnaId,
    this.title,
    this.contents,
    this.secretYn,
  });

  @override
  State<AdQnaWriteScreen> createState() => _AdQnaWriteScreenState();
}

class _AdQnaWriteScreenState extends State<AdQnaWriteScreen> {
  final _titleController = TextEditingController();
  final _contentsController = TextEditingController();

  bool _isSecret = false;
  bool _isLoading = false;
  String? _token;
  String _branchId = '';

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.title ?? '';
    _contentsController.text = widget.contents ?? '';
    _isSecret = widget.secretYn == 'Y';

    _loadCredentials();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentsController.dispose();
    super.dispose();
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('saved_token');
      _branchId = prefs.getString('saved_branch_id') ?? '';
    });
  }

  Future<void> _submitQna() async {
    final title = _titleController.text.trim();
    final contents = _contentsController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요.')),
      );
      return;
    }
    if (contents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문의 내용을 입력해주세요.')),
      );
      return;
    }

    if (_token == null) return;

    setState(() {
      _isLoading = true;
    });

    final appService = RepositoryProvider.of<AppService>(context);
    final secretYnStr = _isSecret ? 'Y' : 'N';

    try {
      Map<String, dynamic>? result;
      if (widget.qnaId != null) {
        result = await appService.updateQna(
          qnaId: int.parse(widget.qnaId!),
          title: title,
          contents: contents,
          secretYn: secretYnStr,
          token: _token!,
          branchId: _branchId,
        );
      } else {
        result = await appService.insertQna(
          productId: widget.productId,
          title: title,
          contents: contents,
          secretYn: secretYnStr,
          token: _token!,
          branchId: _branchId,
        );
      }

      if (result != null && result['success'] == true) {
        final msg = widget.qnaId != null ? '문의글이 수정되었습니다.' : '문의글이 등록되었습니다.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        Navigator.pop(context, true);
      } else {
        final errMsg = result != null ? result['message'] : '서버 오류';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $errMsg')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.qnaId != null ? '상품 문의 수정' : '상품 문의 작성';

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E1A47),
        title: Text(titleText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9100)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('제목', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      hintText: '제목을 입력해 주세요.',
                      hintStyle: const TextStyle(color: Colors.white38),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFF9100)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('문의 내용', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _contentsController,
                    maxLines: 8,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      hintText: '문의하실 내용을 상세히 적어주세요.',
                      hintStyle: const TextStyle(color: Colors.white38),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFF9100)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('비밀글 설정', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      Switch(
                        value: _isSecret,
                        activeColor: const Color(0xFFFF9100),
                        onChanged: (val) {
                          setState(() {
                            _isSecret = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9100),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submitQna,
                    child: Text(
                      widget.qnaId != null ? '수정하기' : '등록하기',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
