// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Box from "@mui/material/Box";
import { Book } from "src/domain/book";

type Props = {
  readonly book: Book;
};

const pages = (book: Book) => {
  return [...Array(book.pageCount).keys()].map((i: number) => (
    <Box
      component="img"
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
  <Box mx="auto">{pages(props.book)}</Box>
);

export default VerticalBookView;
