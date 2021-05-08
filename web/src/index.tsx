// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import CssBaseline from "@material-ui/core/CssBaseline";
import NoSsr from "@material-ui/core/NoSsr";
import { ThemeProvider } from "@material-ui/core/styles";
import { StrictMode } from "react";
import ReactDOM from "react-dom";
import App from "./components/App";
import theme from "./theme";

ReactDOM.render(
  <StrictMode>
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <NoSsr>
        <App />
      </NoSsr>
    </ThemeProvider>
  </StrictMode>,
  document.getElementById("root")
);
