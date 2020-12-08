import React from "react";
import { useParams } from "react-router-dom";

import Box from "@material-ui/core/Box";
import Card from "@material-ui/core/Card";
import Container from "@material-ui/core/Container";
import Grid from "@material-ui/core/Grid";
import Typography from "@material-ui/core/Typography";

import { Book } from "../domain/book";
import { Collection } from "../domain/collection";
import Cover from "./cover";
import Layout from "./layout";

type Props = {
  collections: Collection[];
};

const CollectionPage = (props: Props) => {
  const { id }: { id: string } = useParams();
  const collection: Collection | undefined = props.collections.find(
    (collection) => collection.id === id
  );
  return (
    <Layout collections={props.collections}>
      <Container maxWidth="md">
        <Box my={4}>
          <Typography variant="h4" component="h1" gutterBottom>
            {collection?.name ?? "Loading"}
          </Typography>
        </Box>
      </Container>
      <Container maxWidth="md">
        <Grid container spacing={1}>
          {(collection?.books ?? []).map((book: Book) => (
            <Grid item key={book.id} xs={6} sm={4} md={3}>
              <Cover book={book} />
            </Grid>
          ))}
        </Grid>
      </Container>
    </Layout>
  );
};

export default CollectionPage;
