import { BaseViewModel } from "./BaseViewModel";

@ObservedV2
export class HomeViewModel extends BaseViewModel {
  goToPage(route: string) {
    this.navigateToPage(route);
  }
}