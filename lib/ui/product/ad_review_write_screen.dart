import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/service/app_service.dart';

class AdReviewWriteScreen extends StatefulWidget {
  final int productId;
  final String? reviewId;
  final String? contents;
  final double? rating;
  final String? filePaths;

  const AdReviewWriteScreen({
    super.key,
    required this.productId,
    this.reviewId,
    this.contents,
    this.rating,
    this.filePaths,
  });

  @override
  State<AdReviewWriteScreen> createState() => _AdReviewWriteScreenState();
}

class _AdReviewWriteScreenState extends State<AdReviewWriteScreen> {
  final _contentsController = TextEditingController();
  final _picker = ImagePicker();

  double _rating = 0.0;
  bool _isLoading = false;
  String? _token;
  String _branchId = '';

  // Local files picked
  final List<File> _localImages = [];
  // Existing image urls if edit
  final List<String> _existingUrls = [];

  @override
  void initState() {
    super.initState();
    _contentsController.text = widget.contents ?? '';
    _rating = widget.rating ?? 0.0;

    if (widget.filePaths != null && widget.filePaths!.isNotEmpty) {
      _existingUrls.addAll(widget.filePaths!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }

    _loadCredentials();
  }

  @override
  void dispose() {
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

  Future<void> _pickImage() async {
    if (_localImages.length + _existingUrls.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진은 최대 3개까지만 첨부 가능합니다.')),
      );
      return;
    }

    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _localImages.add(File(picked.path));
      });
    }
  }

  void _removeLocalImage(int idx) {
    setState(() {
      _localImages.removeAt(idx);
    });
  }

  void _removeExistingUrl(int idx) {
    setState(() {
      _existingUrls.removeAt(idx);
    });
  }

  Future<void> _submitReview() async {
    final contents = _contentsController.text.trim();
    if (contents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰 내용을 입력해주세요.')),
      );
      return;
    }
    if (_rating <= 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('별점을 선택해주세요.')),
      );
      return;
    }

    if (_token == null) return;

    setState(() {
      _isLoading = true;
    });

    final appService = RepositoryProvider.of<AppService>(context);
    final allFilePaths = _localImages.map((e) => e.path).toList();

    try {
      Map<String, dynamic>? result;
      if (widget.reviewId != null) {
        // Edit mode
        result = await appService.updateReview(
          reviewId: int.parse(widget.reviewId!),
          rating: _rating,
          contents: contents,
          token: _token!,
          branchId: _branchId,
          filePaths: allFilePaths,
        );
      } else {
        // Insert mode
        result = await appService.insertReview(
          productId: widget.productId,
          rating: _rating,
          contents: contents,
          token: _token!,
          branchId: _branchId,
          filePaths: allFilePaths,
        );
      }

      if (result != null && result['success'] == true) {
        final msg = widget.reviewId != null ? '리뷰가 수정되었습니다.' : '리뷰가 등록되었습니다.';
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
    final title = widget.reviewId != null ? '상품 리뷰 수정' : '상품 리뷰 작성';
    final totalImageCount = _localImages.length + _existingUrls.length;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E1A47),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  const Text('별점을 선택해 주세요', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (idx) {
                      final starVal = idx + 1.0;
                      return IconButton(
                        icon: Icon(
                          _rating >= starVal ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 40,
                        ),
                        onPressed: () {
                          setState(() {
                            _rating = starVal;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  const Text('리뷰 내용', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _contentsController,
                    maxLines: 6,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      hintText: '상품에 대한 후기를 정성껏 작성해 주세요.',
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('사진 첨부 (최대 3장)', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      Text('$totalImageCount/3', style: const TextStyle(color: Colors.white38)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (totalImageCount < 3)
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(Icons.add_a_photo_outlined, color: Colors.white54),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 80,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // Render existing web urls if edit
                              ..._existingUrls.map((url) {
                                final idx = _existingUrls.indexOf(url);
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 80,
                                  height: 80,
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: GestureDetector(
                                          onTap: () => _removeExistingUrl(idx),
                                          child: const CircleAvatar(
                                            radius: 10,
                                            backgroundColor: Colors.black54,
                                            child: Icon(Icons.close, size: 12, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              // Render local picked images
                              ..._localImages.map((file) {
                                final idx = _localImages.indexOf(file);
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 80,
                                  height: 80,
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: GestureDetector(
                                          onTap: () => _removeLocalImage(idx),
                                          child: const CircleAvatar(
                                            radius: 10,
                                            backgroundColor: Colors.black54,
                                            child: Icon(Icons.close, size: 12, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
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
                    onPressed: _submitReview,
                    child: Text(
                      widget.reviewId != null ? '수정하기' : '등록하기',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
