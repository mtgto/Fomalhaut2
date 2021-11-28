// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import CssBaseline from "@mui/material/CssBaseline";
import NoSsr from "@mui/material/NoSsr";
import StyledEngineProvider from "@mui/material/StyledEngineProvider";
import { ThemeProvider } from "@mui/material/styles";
import { StrictMode } from "react";
import ReactDOM from "react-dom";
import App from "./components/App";
import theme from "./theme";

ReactDOM.render(
  <StrictMode>
    <StyledEngineProvider>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <NoSsr>
          <App />
        </NoSsr>
      </ThemeProvider>
    </StyledEngineProvider>
  </StrictMode>,
  document.getElementById("root")
);
