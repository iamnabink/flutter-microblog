import 'package:bloc_test/bloc_test.dart';
import 'package:boticario_news/application/storage/local_storage.dart';
import 'package:boticario_news/domain/errors/domain_error.dart';
import 'package:boticario_news/domain/usecases/load_news.dart';
import 'package:boticario_news/domain/usecases/load_posts.dart';
import 'package:boticario_news/domain/usecases/remove_post.dart';
import 'package:boticario_news/domain/usecases/save_post.dart';
import 'package:boticario_news/ui/helpers/ui_error.dart';
import 'package:boticario_news/ui/pages/feed/cubit/feed_cubit.dart';
import 'package:boticario_news/ui/pages/feed/cubit/feed_state.dart';
import 'package:boticario_news/ui/pages/feed/post_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/mocks.dart';

class LoadNewsSpy extends Mock implements LoadNews {}

class LoadPostsSpy extends Mock implements LoadPosts {}

class SavePostSpy extends Mock implements SavePost {}

class RemovePostSpy extends Mock implements RemovePost {}

class LocalStorageSpy extends Mock implements CacheLocalStorage {}

void main() {
  FeedCubit sut;
  LoadNewsSpy loadNews;
  LoadPostsSpy loadPosts;
  SavePostSpy savePost;
  RemovePostSpy removePost;
  LocalStorageSpy localStorage;

  mockSuccessPost() => when(loadPosts.load()).thenAnswer((_) async => newsList);

  mockError() => when(loadPosts.load()).thenThrow(DomainError.unexpected);

  mockLocalStorageError() =>
      when(localStorage.clear()).thenThrow(DomainError.unexpected);

  setUp(() {
    loadNews = LoadNewsSpy();
    loadPosts = LoadPostsSpy();
    localStorage = LocalStorageSpy();

    sut = FeedCubit(
      loadNews: loadNews,
      loadPosts: loadPosts,
      savePost: savePost,
      removePost: removePost,
      localStorage: localStorage,
    );

    mockSuccessPost();
  });

  blocTest(
    'Should call loadPosts() once when load',
    build: () => sut,
    act: (sut) => sut.load(),
    verify: (_) {
      verify(loadPosts.load()).called(1);
    },
  );

  blocTest(
    'Should emits FeedLoaded on success',
    build: () => sut,
    act: (sut) => sut.load(),
    expect: [
      FeedLoaded([
        NewsViewModel(
          message: newsList[0].message.content,
          date: 'January 20, 2020',
          user: newsList[0].user.name,
        ),
        NewsViewModel(
          message: newsList[1].message.content,
          date: 'January 14, 2018',
          user: newsList[1].user.name,
        ),
      ])
    ],
  );

  blocTest(
    'Should emits FeedLoaded on failure',
    build: () {
      mockError();
      return sut;
    },
    act: (sut) => sut.load(),
    expect: [
      FeedError(UIError.unexpected.description),
    ],
  );

  blocTest<FeedCubit, FeedState>(
    'Should call localStorage.clear() with success',
    build: () => sut,
    act: (sut) => sut.logoutUser(),
    verify: (_) {
      verify(localStorage.clear()).called(1);
    },
  );

  blocTest(
    'Should emits [FeedLoading, FeedError] on logoutUser',
    build: () {
      return sut;
    },
    act: (sut) => sut.logoutUser(),
    expect: [
      FeedLoading(),
      LogoutUser(),
    ],
  );

  blocTest<FeedCubit, FeedState>(
    'Should emits [FeedLoading, FeedError] on failure',
    build: () {
      mockLocalStorageError();
      return sut;
    },
    act: (sut) => sut.logoutUser(),
    expect: [
      FeedLoading(),
      FeedError(UIError.unexpected.description),
    ],
  );
}
