import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gmat_question_bank/constants.dart';
import 'package:gmat_question_bank/layouts/home.dart';
import 'package:gmat_question_bank/state/database.dart';
import 'package:gmat_question_bank/widgets/component_group_decoration.dart';
import 'package:gmat_question_bank/widgets/rich_content.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/question.dart';

class QuestionDetail extends StatefulWidget {
  QuestionDetail({
    super.key,
    required this.railAnimation,
    required this.questionId,
    required this.showSecondList,
  }) : _future = http
            .get(Uri.parse('$GMAT_DATABASE_ENDPOINT/$questionId.json'))
            .then((value) => Question.fromJson(jsonDecode(value.body)));

  final String questionId;
  late final Future<Question> _future;
  final CurvedAnimation railAnimation;
  final bool showSecondList;

  @override
  State<QuestionDetail> createState() => _QuestionDetailState();
}

class _QuestionDetailState extends State<QuestionDetail> {
  bool showExplanations = false;
  int selectedAnswerIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseState>(
      builder: (context, state, child) => FutureBuilder(
        future: widget._future,
        builder: (BuildContext context, AsyncSnapshot<Question> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final question = snapshot.data!;
            state.setQuestionContent(question);
            return Container(
              child: OneTwoTransition(
                animation: widget.railAnimation,
                one: FocusTraversalGroup(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: Column(
                        children: [
                          RichContent(question.question),
                          if (question.answers != null)
                            ListAnswer(answers: question.answers!),
                          if (question.subQuestions != null)
                            Column(
                              children: List.generate(
                                question.subQuestions?.length ?? 0,
                                (index) => Column(
                                  children: [
                                    RichContent(
                                        question.subQuestions![index].question),
                                    ListAnswer(
                                        answers: question
                                            .subQuestions![index].answers),
                                  ],
                                ),
                              ),
                            ),
                          if (!widget.showSecondList)
                            Container(
                              margin: const EdgeInsets.all(8.0),
                              child: FloatingActionButton.extended(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (context) => Stack(
                                      children: [
                                        ExplanationList(
                                            question: snapshot.data!),
                                        Align(
                                          alignment: Alignment.topRight,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: IconButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              icon: Icon(Icons.close),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  );
                                },
                                label: Text(
                                    "Show ${question.explanations.length} explanation${question.explanations.length > 1 ? 's' : ''}"),
                                icon: Icon(Icons.reviews),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                two: FocusTraversalGroup(
                  child: showExplanations
                      ? ExplanationList(
                          question: snapshot.data!,
                        )
                      : Card(
                          margin: EdgeInsets.all(0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16.0),
                                  bottomLeft: Radius.circular(16.0))),
                          child: Center(
                            child: FloatingActionButton.extended(
                              onPressed: () {
                                setState(() {
                                  showExplanations = true;
                                });
                              },
                              label: Text(
                                  "Show ${question.explanations.length} explanation${question.explanations.length > 1 ? 's' : ''}"),
                              icon: Icon(Icons.reviews),
                            ),
                          ),
                        ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class ExplanationList extends StatelessWidget {
  const ExplanationList({super.key, required this.question});
  final Question question;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsetsDirectional.only(end: 10.0),
        itemCount: question.explanations.length,
        itemBuilder: (context, index) {
          final item = ComponentGroupDecoration(
              children: [RichContent(question.explanations[index])]);
          if (index == 0) {
            return item;
          } else {
            return Column(
              children: [SizedBox(height: 10), item],
            );
          }
        });
  }
}

class ListAnswer extends StatefulWidget {
  ListAnswer({super.key, required this.answers});

  final List<String> answers;

  @override
  State<ListAnswer> createState() => _ListAnswerState();
}

class _ListAnswerState extends State<ListAnswer> {
  int selectedAnswerIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.answers.length, (int index) {
        return Card(
          color: index == selectedAnswerIndex
              ? Theme.of(context).colorScheme.surfaceVariant
              : null,
          child: InkWell(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            onTap: () {
              setState(() {
                selectedAnswerIndex = index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: Text(String.fromCharCode(65 + index)),
                  ),
                  SizedBox(
                    width: 8.0,
                  ),
                  Flexible(child: RichContent(widget.answers[index])),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
