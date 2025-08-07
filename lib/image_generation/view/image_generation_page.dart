import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_assistant_1/image_generation/image_generation.dart';
import 'package:ai_assistant_1/repositories/image_generation_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ImageGenerationPage extends StatelessWidget {
  const ImageGenerationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ImageGenerationCubit(
        imageGenerationRepository: context.read<ImageGenerationRepository>(),
      ),
      child: const ImageGenerationView(),
    );
  }
}

class ImageGenerationView extends StatefulWidget {
  const ImageGenerationView({super.key});

  @override
  State<ImageGenerationView> createState() => _ImageGenerationViewState();
}

class _ImageGenerationViewState extends State<ImageGenerationView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Background gradient effect
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.5,
                colors: [
                  Colors.orange.withValues(alpha: 0.1),
                  Colors.pink.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Message history
                Expanded(
                  child:
                      BlocListener<ImageGenerationCubit, ImageGenerationState>(
                    listenWhen: (previous, current) =>
                        previous.messages.length != current.messages.length,
                    listener: (context, state) => _scrollToBottom(),
                    child:
                        BlocBuilder<ImageGenerationCubit, ImageGenerationState>(
                      buildWhen: (previous, current) =>
                          previous.messages != current.messages,
                      builder: (context, state) {
                        if (state.messages.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 64,
                                  color: Colors.orange.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Describe an image to generate',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final message = state.messages[index];
                                    final isUser =
                                        message.author == MessageAuthor.user;
                                    return Align(
                                      alignment: isUser
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.all(16),
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.85,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isUser
                                              ? Colors.orange
                                                  .withValues(alpha: 0.2)
                                              : Colors.white
                                                  .withValues(alpha: 0.05),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isUser
                                                ? Colors.orange
                                                    .withValues(alpha: 0.3)
                                                : Colors.white
                                                    .withValues(alpha: 0.1),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: isUser
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message.text,
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.9),
                                                fontSize: 16,
                                                height: 1.4,
                                              ),
                                            ),
                                            if (message.imageBase64 !=
                                                null) ...[
                                              const SizedBox(height: 12),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: _buildBase64Image(
                                                    message.imageBase64!),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ).animate().fadeIn(duration: 300.ms).slideX(
                                          begin: isUser ? 0.1 : -0.1,
                                          end: 0,
                                          duration: 300.ms,
                                          curve: Curves.easeOutCubic,
                                        );
                                  },
                                  childCount: state.messages.length,
                                ),
                              ),
                            ),
                            // Extra space at bottom for input
                            const SliverPadding(
                              padding: EdgeInsets.only(bottom: 120),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom input area
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A0A0A).withValues(alpha: 0),
                    const Color(0xFF0A0A0A).withValues(alpha: 0.8),
                    const Color(0xFF0A0A0A),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: TextField(
                            controller: _textController,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onChanged: (value) {
                              context
                                  .read<ImageGenerationCubit>()
                                  .updatePrompt(value);
                            },
                            onSubmitted: (_) => _generateImage(),
                            decoration: InputDecoration(
                              hintText:
                                  'Describe the image you want to generate...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      BlocBuilder<ImageGenerationCubit, ImageGenerationState>(
                        buildWhen: (previous, current) =>
                            previous.generationStatus !=
                                current.generationStatus ||
                            previous.currentPrompt != current.currentPrompt,
                        builder: (context, state) {
                          final isLoading = state.generationStatus ==
                              ImageGenerationStatus.loading;
                          final canGenerate =
                              state.currentPrompt.trim().isNotEmpty;

                          return Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.orange.withValues(
                                      alpha: canGenerate ? 0.4 : 0.2),
                                  Colors.orange.withValues(
                                      alpha: canGenerate ? 0.7 : 0.3),
                                ],
                              ),
                              boxShadow: canGenerate
                                  ? [
                                      BoxShadow(
                                        color: Colors.orange
                                            .withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(28),
                                onTap: canGenerate && !isLoading
                                    ? _generateImage
                                    : null,
                                child: isLoading
                                    ? const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.auto_awesome,
                                        color: Colors.white.withValues(
                                          alpha: canGenerate ? 1.0 : 0.5,
                                        ),
                                        size: 24,
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _generateImage() {
    context.read<ImageGenerationCubit>().generateImage();
    _textController.clear();
  }

  Widget _buildBase64Image(String base64String) {
    final Uint8List bytes = base64Decode(base64String);
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'Failed to decode image',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
