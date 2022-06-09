package dev.kameshs.demos;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class GreeterController {

  @RequestMapping("/")
  public String hello() {
    return "Hello from Captain Canary!!\uD83D\uDC25🚀";
  }
}