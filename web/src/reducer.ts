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

type Actions =
  | ReturnType<typeof setLoading>
  | ReturnType<typeof setBooks>
  | ReturnType<typeof setCollections>
  | ReturnType<typeof toggleLike>
  | ReturnType<typeof setCurrentList>
  | ReturnType<typeof setViewMode>
  | ReturnType<typeof setSortOrder>;

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
  return books;
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
      return { ...state, books: action.payload };
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
    default:
      return initialState;
  }
};
