// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import { Book } from "src/domain/book";
import Box from "@mui/material/Box";

type Props = {
  readonly book: Book;
};

const pages = (book: Book) => {
  return [...Array(book.pageCount).keys()].map((i: number) => (
    <Box
      key={i}
      mx="auto"
      width="100%"
      height="100%"
      flexShrink={0}
      sx={{ scrollSnapAlign: "start" }}
    >
      <Box
        component="img"
        my={0}
        mx="auto"
        maxHeight="100%"
        src={`/images/books/${book.id}/pages/${i}`}
        display="block"
      />
    </Box>
  ));
};

const HorizontalBookView = (props: Props) => (
  <Box
    display="flex"
    sx={{
      width: "100%",
      height: "100vh",
      scrollSnapType: "x mandatory",
      overflowX: "auto",
    }}
  >
    {pages(props.book)}
  </Box>
);

export default HorizontalBookView;
