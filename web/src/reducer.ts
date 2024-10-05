// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import React, { createContext } from "react";
import { Book } from "./domain/book.ts";
import { Collection } from "./domain/collection.ts";
import { Filter } from "./domain/filter.ts";
import { message } from "./message.ts";

export const LoadingState = {
  Initial: 0,
  Loading: 1,
  Loaded: 2,
  Error: 3,
} as const;

export type SortOrder = "name" | "readCount";

type LoadingStateType = (typeof LoadingState)[keyof typeof LoadingState];

export interface State {
  readonly loading: LoadingStateType;
  readonly collections: ReadonlyArray<Collection>;
  readonly filters: ReadonlyArray<Filter>;
  readonly books: ReadonlyArray<Book>;
  readonly selectedBookIds: ReadonlyArray<string>;
  readonly viewMode: "left" | "right" | "vertical";
  readonly sortOrder: SortOrder;
}

const SetLoading = "SetLoading" as const;
const SetBooks = "SetBooks" as const;
const SetCollections = "SetCollections" as const;
const ToggleLike = "ToggleLike" as const;
const SetCurrentList = "SetCurrentList" as const;
const SetViewMode = "SetViewMode" as const;
const SetSortOrder = "SetSortOrder" as const;
const AddBookToCollection = "AddBookToCollection" as const;

type Actions =
  | ReturnType<typeof setLoading>
  | ReturnType<typeof setBooks>
  | ReturnType<typeof setCollections>
  | ReturnType<typeof toggleLike>
  | ReturnType<typeof setCurrentList>
  | ReturnType<typeof setViewMode>
  | ReturnType<typeof setSortOrder>
  | ReturnType<typeof addBookToCollection>;

// eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
export const setLoading = (LoadingState: LoadingStateType) => ({
  type: SetLoading,
  payload: LoadingState,
});

// eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
export const setCollections = (collections: Collection[]) => ({
  type: SetCollections,
  payload: collections,
});

// eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
export const setBooks = (books: Book[]) => ({
  type: SetBooks,
  payload: books,
});

// eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
export const toggleLike = (bookId: string) => ({
  type: ToggleLike,
  payload: bookId,
});

// eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
export const setCurrentList = (selectedBookIds: ReadonlyArray<string>) => ({
  type: SetCurrentList,
  payload: selectedBookIds,
});

export const setViewMode = (viewMode: State["viewMode"]) => ({
  type: SetViewMode,
  payload: viewMode,
});

export const setSortOrder = (sortOrder: SortOrder) => ({
  type: SetSortOrder,
  payload: sortOrder,
});

export const addBookToCollection = (bookId: string, collectionId: string) => ({
  type: AddBookToCollection,
  payload: [bookId, collectionId],
});

const loadLocalStorage = (): {
  viewMode: State["viewMode"];
  sortOrder: SortOrder;
} => {
  const value = localStorage.getItem("net.mtgto.Fomalhaut2");
  let sortOrder: SortOrder = "name";
  if (value) {
    const obj = JSON.parse(value);
    const viewMode = obj["viewMode"];
    const sortOrderRaw = obj["sortOrder"];
    if (
      viewMode === "left" ||
      viewMode === "right" ||
      viewMode === "vertical"
    ) {
      if (sortOrderRaw === "name" || sortOrderRaw === "readCount") {
        sortOrder = sortOrderRaw;
      }
      return { viewMode, sortOrder };
    }
  }
  return { viewMode: "right", sortOrder };
};

const saveLocalStorage = (
  viewMode: State["viewMode"],
  sortOrder: SortOrder
) => {
  const item = localStorage.getItem("net.mtgto.Fomalhaut2");
  if (item) {
    localStorage.setItem(
      "net.mtgto.Fomalhaut2",
      JSON.stringify({ viewMode, sortOrder })
    );
  }
};

const sortBooks = (
  sortOrder: SortOrder,
  books: ReadonlyArray<Book>
): ReadonlyArray<Book> => {
  return [...books].sort((a: Book, b: Book): number => {
    switch (sortOrder) {
      case "name":
        if (a.name < b.name) {
          return -1;
        } else if (a.name > b.name) {
          return 1;
        } else {
          return 0;
        }
      case "readCount": // order by desc
        if (a.readCount < b.readCount) {
          return 1;
        } else if (a.readCount > b.readCount) {
          return -1;
        } else {
          return 0;
        }
    }
  });
};

const addBook = (bookId: string, collection: Collection): Collection => {
  if (collection.bookIds.includes(bookId)) {
    return collection;
  } else {
    return { ...collection, bookIds: collection.bookIds.concat(bookId) };
  }
};

export const initialState: State = {
  loading: LoadingState.Initial,
  collections: [],
  filters: [
    new Filter("all", message.filter.all, () => true),
    new Filter(
      "unread",
      message.filter.unread,
      (book: Book) => book.readCount === 0
    ),
    new Filter("like", message.filter.like, (book: Book) => book.like),
  ],
  books: [],
  selectedBookIds: [],
  ...loadLocalStorage(),
};

export const StateContext = createContext<{
  state: State;
  dispatch: React.Dispatch<Actions>;
}>({ state: initialState, dispatch: () => null });

export const reducer = (state: State, action: Actions): State => {
  switch (action.type) {
    case SetLoading:
      return { ...state, loading: action.payload };
    case SetCollections:
      return { ...state, collections: action.payload };
    case SetBooks:
      return { ...state, books: sortBooks(state.sortOrder, action.payload) };
    case ToggleLike:
      return {
        ...state,
        books: state.books.map((book) =>
          book.id === action.payload ? { ...book, like: !book.like } : book
        ),
      };
    case SetCurrentList:
      return {
        ...state,
        selectedBookIds: action.payload,
      };
    case SetViewMode:
      saveLocalStorage(action.payload, state.sortOrder);
      return {
        ...state,
        viewMode: action.payload,
      };
    case SetSortOrder:
      saveLocalStorage(state.viewMode, action.payload);
      return {
        ...state,
        books: sortBooks(action.payload, state.books),
        sortOrder: action.payload,
      };
    case AddBookToCollection:
      return {
        ...state,
        collections: state.collections.map((collection) => {
          if (collection.id === action.payload[0]) {
            return addBook(action.payload[1], collection);
          } else {
            return collection;
          }
        }),
      };
    default:
      return initialState;
  }
};
