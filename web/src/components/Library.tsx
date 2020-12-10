import React from "react";

import Box from "@material-ui/core/Box";
import Container from "@material-ui/core/Container";
import Grid from "@material-ui/core/Grid";
import Typography from "@material-ui/core/Typography";

import { Book } from "../domain/book";
import { Collection } from "../domain/collection";
import Cover from "./Cover";
import Layout from "./Layout";

type Props = {
  collections: Collection[];
  books: Book[];
  title: string;
};

const Library = (props: Props) => {
  return (
    <Layout collections={props.collections}>
      <Container maxWidth="md">
        <Box my={4}>
          <Typography variant="h4" component="h1" gutterBottom>
            {props.title}
          </Typography>
        </Box>
      </Container>
      <Container maxWidth="md">
        <Grid container spacing={4}>
          {props.books.map((book: Book) => (
            <Grid item key={book.id} xs={6} sm={4} md={3}>
              <Cover book={book} />
            </Grid>
          ))}
        </Grid>
      </Container>
    </Layout>
  );
};
export default Library;
