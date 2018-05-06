defmodule AcmeTest do
  use ExUnit.Case
  alias Acme.BankOfHours

  test "Calc employee total daily work time" do
    entries1 = [
      "2018-04-25T20:50:00",
      "2018-04-25T21:50:00"
    ]

    entries2 = [
      "2018-04-25T20:50:00",
      "2018-04-25T21:50:00",
      "2018-04-25T22:40:00"
    ]

    entries3 = [
      "2018-04-25T20:50:00",
      "2018-04-25T21:50:00",
      "2018-04-25T22:40:00",
      "2018-04-25T23:45:00"
    ]

    entries4 = [
      "2018-04-25T20:50:00",
      "2018-04-25T21:50:00",
      "2018-04-25T22:40:00",
      "2018-04-25T23:45:00",
      "2018-04-25T23:30:00"
    ]

    assert BankOfHours.calc_work(entries1) == 60
    assert BankOfHours.calc_work(entries2) == 60
    assert BankOfHours.calc_work(entries3) == 125
    assert BankOfHours.calc_work(entries4) == 125
  end

  test "Calc employee daily unrest time" do
    entries1 = [
      "2018-04-25T20:50:00",
      "2018-04-25T21:50:00"
    ]

    entries2 = [
      "2018-04-25T20:50:00",
      "2018-04-25T21:50:00",
      "2018-04-25T21:55:00"
    ]

    assert BankOfHours.calc_unrested_time(entries1, 60, 50, 10) == 10
    assert BankOfHours.calc_unrested_time(entries1, 125, 100, 40) == 40
    assert BankOfHours.calc_unrested_time(entries1, 125, 600, 60) == 0
    assert BankOfHours.calc_unrested_time(entries2, 60, 50, 10) == 5
  end
end
