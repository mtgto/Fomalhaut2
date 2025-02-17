// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import CssBaseline from "@mui/material/CssBaseline";
import NoSsr from "@mui/material/NoSsr";
import { red } from "@mui/material/colors";
import { createTheme, ThemeProvider } from "@mui/material/styles";
import useMediaQuery from "@mui/material/useMediaQuery";
import { useEffect, useMemo, useReducer } from "react";
import { RoconRoot } from "rocon/react";
import { Book } from "../domain/book.ts";
import { Collection } from "../domain/collection.ts";
import {
  initialState,
  LoadingState,
  reducer,
  setBooks,
  setCollections,
  setLoading,
  StateContext,
} from "../reducer.ts";
import Routes from "./Routes.tsx";

type ApiBook = Omit<Book, "createdAt"> & { createdAt: string };

const parseBook = (book: ApiBook): Book =>
  new Book(
    book.id,
    book.name,
    book.pageCount,
    book.readCount,
    book.like,
    book.isRightToLeft,
    new Date(book.createdAt)
  );

const App: React.FunctionComponent = () => {
  const prefersDarkMode = useMediaQuery("(prefers-color-scheme: dark)");
  const [state, dispatch] = useReducer(reducer, initialState);

  const theme = useMemo(
    () =>
      createTheme({
        palette: {
          mode: prefersDarkMode ? "dark" : "light",
          primary: {
            main: "#556cd6",
          },
          secondary: {
            main: "#19857b",
          },
          error: {
            main: red.A400,
          },
        },
        typography: {
          fontFamily: [
            "-apple-system",
            "BlinkMacSystemFont",
            '"Segoe UI"',
            "Roboto",
            '"Helvetica Neue"',
            "Arial",
            "sans-serif",
            '"Apple Color Emoji"',
            '"Segoe UI Emoji"',
            '"Segoe UI Symbol"',
          ].join(","),
        },
      }),
    [prefersDarkMode]
  );

  useEffect(() => {
    // Fetch All books
    async function fetchBooks() {
      const books = await fetch("/api/v1/books")
        .then((response) => response.json())
        .then((books: ApiBook[]) => books.map((book) => parseBook(book)));
      dispatch(setBooks(books));
    }
    async function fetchCollections() {
      const collections: Collection[] = await fetch("/api/v1/collections")
        .then((response) => response.json())
        .then((collections: { id: string; name: string; books: ApiBook[] }[]) =>
          collections.map(
            (collection) =>
              new Collection(
                collection.id,
                collection.name,
                collection.books.map((book) => parseBook(book))
              )
          )
        );
      dispatch(setCollections(collections));
    }
    dispatch(setLoading(LoadingState.Loading));
    Promise.all([fetchBooks(), fetchCollections()])
      .then(() => setLoading(LoadingState.Loaded))
      .catch((error) => {
        console.error(error);
        dispatch(setLoading(LoadingState.Error));
      });
  }, []);

  return (
    <ThemeProvider theme={theme}>
      <StateContext.Provider value={{ state, dispatch }}>
        <CssBaseline />
        <RoconRoot>
          <NoSsr>
            <Routes />
          </NoSsr>
        </RoconRoot>
      </StateContext.Provider>
    </ThemeProvider>
  );
};
export default App;
