// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Box from "@material-ui/core/Box";
import Container from "@material-ui/core/Container";
import Grid from "@material-ui/core/Grid";
import Typography from "@material-ui/core/Typography";
import Pagination from "@material-ui/lab/Pagination";
import React from "react";
import { Book } from "../domain/book";
import Cover from "./Cover";
import Layout from "./Layout";

type Props = {
  readonly books: ReadonlyArray<Book>;
  readonly title: string;
  readonly page: number | undefined;
  readonly pageChanged: (page: number) => void;
};

const Library: React.VoidFunctionComponent<Props> = (props: Props) => {
  const handleChangePage = (_e: React.ChangeEvent<unknown>, page: number) => {
    props.pageChanged(page);
  };
  const numberOfBooksPerPage = 20;
  const pageCount = Math.ceil(props.books.length / numberOfBooksPerPage);
  const books = props.books.slice(
    ((props.page ?? 1) - 1) * numberOfBooksPerPage,
    ((props.page ?? 1) - 1) * numberOfBooksPerPage + numberOfBooksPerPage
  );
  return (
    <Layout>
      <Container maxWidth="md">
        <Box my={4}>
          <Typography variant="h4" component="h1" gutterBottom>
            {props.title} {props.books.length > 0 && `(${props.books.length})`}
          </Typography>
        </Box>
      </Container>
      <Container maxWidth="md">
        <Grid container>
          {books.map((book: Book) => (
            <Grid item key={book.id} xs={6} sm={4} md={3}>
              <Cover book={book} />
            </Grid>
          ))}
        </Grid>
        <Box display="flex" justifyContent="center" pt={4} pb={4}>
          <Pagination
            count={pageCount}
            page={props.page ?? 1}
            onChange={handleChangePage}
          />
        </Box>
      </Container>
    </Layout>
  );
};
export default Library;
