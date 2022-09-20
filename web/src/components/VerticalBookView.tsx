// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Box from "@mui/material/Box";
import { Book } from "src/domain/book";
import NavigationPage from "./NavigationPage";

type Props = Readonly<{
  book: Book;
  nextBook?: Book;
  onNext: () => void;
  onRandom: () => void;
}>;

const pages = (book: Book) => {
  return [...Array(book.pageCount).keys()].map((i: number) => (
    <Box
      component="img"
      loading="lazy"
      my={1}
      mx="auto"
      display="block"
      width="100%"
      maxWidth="720px"
      minHeight="200px"
      key={`${book.id}.${i}`}
      src={`/images/books/${book.id}/pages/${i}`}
    />
  ));
};

const VerticalBookView = (props: Props) => (
  <Box mx="auto">
    {pages(props.book)}
    <Box
      display="flex"
      flexDirection="column"
      justifyContent="center"
      alignItems="center"
      width="100%"
      height="100vh"
    >
      <NavigationPage
        book={props.book}
        nextBook={props.nextBook}
        onNext={props.onNext}
        onRandom={props.onRandom}
      />
    </Box>
  </Box>
);

export default VerticalBookView;
