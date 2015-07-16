Require Import Recdef.
Require Import NArith.
Require Import sets.
Require Import tarski_to_col_theory.

Module SSWP := WPropertiesOn SetOfSetsOfPositiveOrderedType SS.

Module SSWEqP := WEqPropertiesOn SetOfSetsOfPositiveOrderedType SS.

Module SPWEqP := WEqPropertiesOn SetOfPairsOfPositiveOrderedType SP.

Definition have_pair_distinct_points (s : SS.elt) (sp : SP.t) :=
  SP.exists_ (fun p => (S.mem (fstpp p) s) && (S.mem (sndpp p) s)) sp.

Lemma proper_00 : forall s,
  Proper
  ((fun t1 t2 : SetOfPairsOfPositiveOrderedType.t =>
    Pos.eq (fstpp t1) (fstpp t2) /\ Pos.eq (sndpp t1) (sndpp t2)) ==> eq)
  (fun p : SP.elt =>
   S.mem (fstpp p) s && S.mem (sndpp p) s).
Proof.
intros s x y Hxy.
destruct Hxy as [Hxyfst Hxysnd].
rewrite Hxyfst.
rewrite Hxysnd.
reflexivity.
Qed.

Lemma proper_0 : 
  Proper (S.Equal ==> eq ==> eq)
   have_pair_distinct_points .
Proof.
intros x1 y1 HXY1.
intros x2 y2 HXY2.
unfold have_pair_distinct_points; unfold SP.exists_; unfold SP.Raw.exists_.
rewrite HXY2.
induction (SP.this y2); try intuition.

  assert (HEqMem : forall e, S.mem e x1 = S.mem e y1)
    by (intro; apply SWP.Dec.F.mem_m; intuition).
  assert (HEqAI : (S.mem (fstpp a) x1 && S.mem (sndpp a) x1) =
                  (S.mem (fstpp a) y1 && S.mem (sndpp a) y1))
    by (rewrite HEqMem; rewrite HEqMem; intuition).
  rewrite HEqAI.
  induction (S.mem (fstpp a) y1 && S.mem (sndpp a) y1);
    intuition.
Qed.

Lemma proper_1 : forall s1 sp,
  Proper (S.Equal ==> eq)
  (fun s2 : SS.elt => have_pair_distinct_points (S.inter s1 s2) sp).
Proof.
intros s1 sp.
intros x y HXY.
assert (HEqI : S.Equal (S.inter s1 x) (S.inter s1 y))
  by (apply SWP.inter_equal_2; assumption).
apply proper_0; auto.
Qed.

Definition exists_witness (f : SS.elt -> bool) (s : SS.t) : option SS.elt :=
  SS.choose (SS.filter f s).

Lemma exists_witness_ok : forall e f s,
  Proper (S.Equal ==> eq) f ->
  exists_witness f s = Some e -> SS.In e s.
Proof.
intros e f s HP H.
unfold exists_witness in H.
apply SSWEqP.MP.Dec.F.mem_2.
apply SSWEqP.choose_mem_1 in H.
rewrite SSWEqP.filter_mem in H; try assumption.
apply andb_true_iff in H.
induction H.
assumption.
Qed.

Definition get_suitable_pair_of_sets_aux (s1 : SS.elt)
                                         (ss : SS.t)
                                         (sp : SP.t)
                                         : (option (SS.elt * SS.elt)) :=
  match ((exists_witness (fun s2 => let i := S.inter s1 s2 in
                                      have_pair_distinct_points i sp)) ss) with
    | None => None
    | Some s2 => Some(s1,s2)
  end.

Definition get_suitable_pair_of_sets (ss : SS.t) (sp : SP.t)
                                     : (option (SS.elt * SS.elt)) :=
  match (exists_witness (fun s =>
                           match (get_suitable_pair_of_sets_aux s (SS.remove s ss) sp) with
                             | None => false
                             | _ => true
                           end) ss) with
    | None => None
    | Some s1 => get_suitable_pair_of_sets_aux s1 (SS.remove s1 ss) sp
  end.

Definition eqop (p1 p2 : option SS.elt) :=
  match p1,p2 with
    | None, None => True
    | Some s1, Some s2 => True
    | _, _ => False
  end.

Lemma proper_2 : forall (f1 f2 : SS.elt -> bool) (s1 s2 : SS.t),
  Proper (S.Equal ==> eq) f1 ->
  Proper (S.Equal ==> eq) f2 ->
  (forall x, f1 x = f2 x) ->
  SS.Equal s1 s2 ->
  eqop (exists_witness f1 s1) (exists_witness f2 s2).
Proof.
intros f1 f2 s1 s2.
intros H1 H2 H3 H4.
unfold eqop.
unfold exists_witness in *.
assert (SS.Equal (SS.filter f1 s1) (SS.filter f2 s2)) by (apply SSWEqP.MP.Dec.F.filter_ext; assumption).
case_eq (SS.choose (SS.filter f1 s1)); case_eq (SS.choose (SS.filter f2 s2)).

  intuition.

  intros HCN e HCS.
  apply SS.choose_spec1 in HCS.
  apply SS.choose_spec2 in HCN.
  rewrite H in HCS.
  apply SSWEqP.MP.empty_is_empty_1 in HCN.
  rewrite HCN in HCS.
  rewrite <- SSWEqP.MP.Dec.F.empty_iff.
  eassumption.

  intros e HCS HCN.
  apply SS.choose_spec1 in HCS.
  apply SS.choose_spec2 in HCN.
  rewrite H in HCN.
  apply SSWEqP.MP.empty_is_empty_1 in HCN.
  rewrite HCN in HCS.
  rewrite <- SSWEqP.MP.Dec.F.empty_iff.
  eassumption.

  intuition.
Qed.

Definition eqopp (p1 p2 : option (SS.elt * SS.elt)) :=
  match p1,p2 with
    | None, None => True
    | Some s1, Some s2 => True
    | _, _ => False
  end.

Lemma proper_3 : Proper (S.Equal ==> SS.Equal ==> eq ==> eqopp) get_suitable_pair_of_sets_aux.
Proof.
intros x1 y1 HXY1.
intros x2 y2 HXY2.
intros x3 y3 HXY3.
unfold get_suitable_pair_of_sets_aux.
rewrite HXY3.
assert (eqop (exists_witness (fun s2 : SS.elt => have_pair_distinct_points (S.inter x1 s2) y3) x2)
             (exists_witness (fun s2 : SS.elt => have_pair_distinct_points (S.inter y1 s2) y3) y2)).

  apply proper_2.

    apply proper_1.

    apply proper_1.

    intro; apply proper_0; try reflexivity.

      apply SWP.inter_equal_1; assumption.

      assumption.

case_eq (exists_witness (fun s2 : SS.elt => have_pair_distinct_points (S.inter y1 s2) y3) y2);
case_eq (exists_witness (fun s2 : SS.elt => have_pair_distinct_points (S.inter x1 s2) y3) x2).

  simpl; intuition.

  intros HCN e HCS.
  simpl in *.
  rewrite HCS in H; rewrite HCN in H.
  simpl in *.
  intuition.

  intros e HCS HCN.
  simpl in *.
  rewrite HCS in H; rewrite HCN in H.
  simpl in *.
  intuition.

  intuition.
Qed.

Lemma get_suitable_pair_of_sets_ok_1 : forall s1 s2 ss sp,
  get_suitable_pair_of_sets ss sp = Some(s1,s2) ->
  SS.In s1 ss.
Proof.
intros s1 s2 ss sp H.
unfold get_suitable_pair_of_sets in H.
case_eq (exists_witness (fun s : SS.elt => match get_suitable_pair_of_sets_aux s
                          (SS.remove s ss) sp with | Some _ => true | None => false end) ss).

  intros e1 HEW1.
  rewrite HEW1 in H.
  unfold get_suitable_pair_of_sets_aux in H.
  case_eq (exists_witness (fun s2 : SS.elt => have_pair_distinct_points (S.inter e1 s2) sp) (SS.remove e1 ss)).

    intros e2 HEW2.
    rewrite HEW2 in H.
    assert (HEq1 : e1 = s1) by (injection H; intros; assumption).
    rewrite HEq1 in *.
    assert (HEq2 : e2 = s2) by (injection H; intros; assumption).
    rewrite HEq2 in *.
    apply exists_witness_ok with (fun s : SS.elt => 
      match get_suitable_pair_of_sets_aux s (SS.remove s ss) sp with | Some _ => true | None => false end).
    intros x y HXY.
    assert (SS.Equal (SS.remove x ss) (SS.remove y ss))
      by (apply SSWP.Dec.F.remove_m; try assumption; reflexivity).
    assert (eqopp (get_suitable_pair_of_sets_aux x (SS.remove x ss) sp) (get_suitable_pair_of_sets_aux y (SS.remove y ss) sp)).
    apply proper_3; auto.
    case_eq (get_suitable_pair_of_sets_aux x (SS.remove x ss) sp);
      intros;
      case_eq (get_suitable_pair_of_sets_aux y (SS.remove y ss) sp);
      intros.
      reflexivity.

      rewrite H2 in H1; rewrite H3 in H1.
      unfold eqop in H1; simpl in H1.
      intuition.
      rewrite H2 in H1; rewrite H3 in H1.
      unfold eqop in H1; simpl in H1.
      intuition.
      reflexivity.

    assumption.

    intro HEW2.
    rewrite HEW2 in H.
    discriminate.

  intro HEW.
  rewrite HEW in H.
  discriminate.
Qed.

Lemma get_suitable_pair_of_sets_ok_2 : forall s1 s2 ss sp,
  get_suitable_pair_of_sets ss sp = Some(s1,s2) ->
  SS.In s2 (SS.remove s1 ss).
Proof.
intros s1 s2 ss sp H.
unfold get_suitable_pair_of_sets in H.
case_eq (exists_witness (fun s : SS.elt => match get_suitable_pair_of_sets_aux s
                          (SS.remove s ss) sp with | Some _ => true | None => false end) ss).

  intros e1 HEW1.
  rewrite HEW1 in H.
  unfold get_suitable_pair_of_sets_aux in H.
  case_eq (exists_witness (fun s2 : SS.elt => have_pair_distinct_points (S.inter e1 s2) sp) (SS.remove e1 ss)).

    intros e2 HEW2.
    rewrite HEW2 in H.
    assert (HEq1 : e1 = s1) by (injection H; intros; assumption).
    rewrite HEq1 in *.
    assert (HEq2 : e2 = s2) by (injection H; intros; assumption).
    rewrite HEq2 in *.
    apply exists_witness_ok with (fun s2 : SS.elt => have_pair_distinct_points (S.inter s1 s2) sp).
    intros x y HXY.
    apply proper_1; assumption.
    assumption.

    intro HEW2.
    rewrite HEW2 in H.
    discriminate.

  intro HEW.
  rewrite HEW in H.
  discriminate.
Qed.

Function compute_new_set_of_sets_of_collinear_points (ss : SS.t)
                                                     (sp : SP.t)
                                                     {measure SS.cardinal ss}
                                                     : SS.t :=
  let suitablepairofsets := get_suitable_pair_of_sets ss sp in
    match suitablepairofsets with
      |None => ss
      |Some (s1,s2) => let auxsetofsets := SS.remove s2 (SS.remove s1 ss) in
                       let auxset := S.union s1 s2 in
                       let newss := SS.add auxset auxsetofsets in
                         compute_new_set_of_sets_of_collinear_points newss sp
    end.
Proof.
intros.
assert (S(SS.cardinal (SS.remove s1 ss)) = SS.cardinal ss).
apply SSWP.remove_cardinal_1.
apply get_suitable_pair_of_sets_ok_1 with s2 sp.
assumption.
assert (S(S(SS.cardinal (SS.remove s2 (SS.remove s1 ss)))) = S(SS.cardinal (SS.remove s1 ss))).
apply eq_S.
apply SSWP.remove_cardinal_1.
apply get_suitable_pair_of_sets_ok_2 with sp.
assumption.
assert (HR1 : S(S(SS.cardinal (SS.remove s2 (SS.remove s1 ss)))) = SS.cardinal ss).
transitivity (S(SS.cardinal (SS.remove s1 ss))); assumption.
elim (SSWP.In_dec (S.union s1 s2) (SS.remove s2 (SS.remove s1 ss))); intro HDec.

  assert (HR2 : SS.cardinal (SS.add (S.union s1 s2) (SS.remove s2 (SS.remove s1 ss))) = SS.cardinal (SS.remove s2 (SS.remove s1 ss))).
  apply SSWP.add_cardinal_1; assumption.
  rewrite HR2.
  rewrite <- HR1.
  omega.

  assert (HR2 : SS.cardinal (SS.add (S.union s1 s2) (SS.remove s2 (SS.remove s1 ss))) = S( SS.cardinal (SS.remove s2 (SS.remove s1 ss)))).
  apply SSWP.add_cardinal_2; assumption.
  rewrite HR2.
  rewrite <- HR1.
  omega.
Defined.

Definition test_col (ss : SS.t) (sp : SP.t) p1 p2 p3 : bool :=
  let newss := compute_new_set_of_sets_of_collinear_points ss sp  in
    SS.exists_ (fun s => S.mem p1 s && S.mem p2 s && S.mem p3 s) newss.

Section Col_refl.

Context `{CT:Col_theory}.

Lemma CTcol_permutation_5 : forall A B C : COLTpoint, CTCol A B C -> CTCol A C B.
Proof.
apply CTcol_permutation_2.
Qed.

Lemma CTcol_permutation_2 : forall A B C : COLTpoint, CTCol A B C -> CTCol C A B.
Proof.
intros.
apply CTcol_permutation_1.
apply CTcol_permutation_1.
assumption.
Qed.

Lemma CTcol_permutation_3 : forall A B C : COLTpoint, CTCol A B C -> CTCol C B A.
Proof.
intros.
apply CTcol_permutation_5.
apply CTcol_permutation_2.
assumption.
Qed.

Lemma CTcol_permutation_4 : forall A B C : COLTpoint, CTCol A B C -> CTCol B A C.
Proof.
intros.
apply CTcol_permutation_5.
apply CTcol_permutation_1.
assumption.
Qed.

Lemma CTcol_trivial_1 : forall A B : COLTpoint, CTCol A A B.
Proof.
apply CTcol_trivial.
Qed.

Lemma CTcol_trivial_2 : forall A B : COLTpoint, CTCol A B B.
Proof.
intros.
apply CTcol_permutation_2.
apply CTcol_trivial_1.
Qed.

Definition ss_ok (ss : SS.t) (interp: positive -> COLTpoint) :=
  forall s, SS.mem s ss = true -> 
  forall p1 p2 p3, S.mem p1 s && S.mem p2 s && S.mem p3 s = true ->
    CTCol (interp p1) (interp p2) (interp p3).

Definition sp_ok (sp : SP.t) (interp: positive -> COLTpoint) :=
  forall p, SP.mem p sp = true -> interp (fstpp p) <> interp (sndpp p).

Lemma compute_new_set_of_sets_of_collinear_points_ok : forall ss sp interp,
  ss_ok ss interp -> sp_ok sp interp ->
  ss_ok (compute_new_set_of_sets_of_collinear_points ss sp) interp.
Proof.
intros ss sp interp HSS HSP.
apply (let P interp ss sp newss :=
       ss_ok ss interp -> sp_ok sp interp -> ss_ok newss interp in
         compute_new_set_of_sets_of_collinear_points_ind (P interp)); try assumption.

  intros.
  assumption.

  clear HSS; clear HSP; clear ss; clear sp.
  intros ss sp suitablepairofsets s1 s2 Hs1s2 auxsetofsets auxset newss H HSS HSP.
  assert (Hs1 := Hs1s2).
  assert (Hs2 := Hs1s2).
  apply get_suitable_pair_of_sets_ok_1 in Hs1.
  apply get_suitable_pair_of_sets_ok_2 in Hs2.
  apply SSWEqP.MP.Dec.F.remove_3 in Hs2.
  apply H; try assumption; clear H.
  intros s Hmem p1 p2 p3 Hmemp.
  do 2 (rewrite andb_true_iff in Hmemp).
  destruct Hmemp as [[Hmemp1 Hmemp2] Hmemp3].
  unfold newss in Hmem; clear newss.
  elim (SS.E.eq_dec auxset s); intro HEq.

    rewrite <- HEq in *; clear HEq; clear s.
    unfold suitablepairofsets in Hs1s2; clear suitablepairofsets.
    unfold get_suitable_pair_of_sets in Hs1s2.
    case_eq (exists_witness
            (fun s : SS.elt =>
             match get_suitable_pair_of_sets_aux s (SS.remove s ss) sp with
             | Some _ => true
             | None => false
             end) ss); try (intro HEW; rewrite HEW in *; discriminate).
    intros e1 HEW; rewrite HEW in *; clear HEW.
    unfold get_suitable_pair_of_sets_aux in *.
    case_eq (exists_witness
            (fun s2 : SS.elt => have_pair_distinct_points (S.inter e1 s2) sp)
            (SS.remove e1 ss)); try (intro HEW; rewrite HEW in *; discriminate).
    intros e2 HEW; rewrite HEW in *.
    injection Hs1s2; intros He2s2 He1s1.
    rewrite He2s2 in *; rewrite He1s1 in *; clear He2s2; clear He1s1; clear Hs1s2; clear e2; clear e1.
    case_eq (have_pair_distinct_points (S.inter s1 s2) sp).

      clear HEW; intro HEW.
      unfold have_pair_distinct_points in HEW.
      apply SPWEqP.exists_mem_4 in HEW; try (apply proper_00).
      destruct HEW as [x [HmemSP HmemS]].
      rewrite andb_true_iff in HmemS; destruct HmemS as [Hmemfsts Hmemsnds].
      apply HSP in HmemSP.
      apply SWP.Dec.F.mem_2 in Hmemfsts.
      apply S.inter_spec in Hmemfsts.
      destruct Hmemfsts as [Hfss1 Hfss2].
      apply SWP.Dec.F.mem_2 in Hmemsnds.
      apply S.inter_spec in Hmemsnds.
      destruct Hmemsnds as [Hsss1 Hsss2].
      unfold auxset in *.
      apply CTcol3 with (interp (fstpp(x))) (interp (sndpp(x))); try assumption.

        apply SWP.Dec.F.mem_2 in Hmemp1.
        apply SWP.Dec.F.union_1 in Hmemp1.
        elim (Hmemp1); intro HInp1.

          apply HSS with s1.
          apply SSWP.Dec.F.mem_1; assumption.
          do 2 (rewrite andb_true_iff).
          repeat split; apply SWP.Dec.F.mem_1; assumption.

          apply HSS with s2.
          apply SSWP.Dec.F.mem_1; assumption.
          do 2 (rewrite andb_true_iff).
          repeat split; apply SWP.Dec.F.mem_1; assumption.

        apply SWP.Dec.F.mem_2 in Hmemp2.
        apply SWP.Dec.F.union_1 in Hmemp2.
        elim (Hmemp2); intro HInp2.

          apply HSS with s1.
          apply SSWP.Dec.F.mem_1; assumption.
          do 2 (rewrite andb_true_iff).
          repeat split; apply SWP.Dec.F.mem_1; assumption.

          apply HSS with s2.
          apply SSWP.Dec.F.mem_1; assumption.
          do 2 (rewrite andb_true_iff).
          repeat split; apply SWP.Dec.F.mem_1; assumption.

        apply SWP.Dec.F.mem_2 in Hmemp3.
        apply SWP.Dec.F.union_1 in Hmemp3.
        elim (Hmemp3); intro HInp3.

          apply HSS with s1.
          apply SSWP.Dec.F.mem_1; assumption.
          do 2 (rewrite andb_true_iff).
          repeat split; apply SWP.Dec.F.mem_1; assumption.

          apply HSS with s2.
          apply SSWP.Dec.F.mem_1; assumption.
          do 2 (rewrite andb_true_iff).
          repeat split; apply SWP.Dec.F.mem_1; assumption.

      intro HEW2; unfold exists_witness in *; apply SS.choose_spec1 in HEW.
      apply SSWEqP.MP.Dec.F.filter_2 in HEW; try apply proper_1.
      rewrite HEW2 in *; discriminate.

    rewrite SSWP.Dec.F.add_neq_b in Hmem; try assumption.
    apply HSS with s.
    unfold auxsetofsets in *.
    apply SSWEqP.MP.Dec.F.mem_2 in Hmem.
    do 2 (apply SSWEqP.MP.Dec.F.remove_3 in Hmem).
    apply SSWEqP.MP.Dec.F.mem_1.
    assumption.
    do 2 (rewrite andb_true_iff).
    repeat split; assumption.
Qed.

Lemma test_col_ok : forall ss sp interp p1 p2 p3,
  ss_ok ss interp -> sp_ok sp interp ->
  test_col ss sp p1 p2 p3 = true ->
  CTCol (interp p1) (interp p2) (interp p3).
Proof.
intros ss sp interp p1 p2 p3 HSS HSP HTC.
unfold test_col in *.
assert (HSS2 : ss_ok (compute_new_set_of_sets_of_collinear_points ss sp) interp)
  by (apply compute_new_set_of_sets_of_collinear_points_ok; assumption).

unfold ss_ok in HSS2.
apply SSWEqP.MP.Dec.F.exists_2 in HTC.
unfold SS.Exists in HTC.
destruct HTC as [s [HIn Hmem]].
apply HSS2 with s.
apply SSWEqP.MP.Dec.F.mem_1.
assumption.
assumption.

intros x y Hxy.
assert (HmemEq : forall p, S.mem p x = S.mem p y)
  by (intro; apply SWP.Dec.F.mem_m; auto).
do 3 (rewrite HmemEq); reflexivity.
Qed.

Lemma ss_ok_empty : forall interp, 
  ss_ok SS.empty interp.
Proof.
intros interp ss Hmem1 p1 p2 p3 Hmem2.
rewrite SSWEqP.MP.Dec.F.empty_b in Hmem1.
discriminate.
Qed.

Lemma sp_ok_empty : forall interp, 
  sp_ok SP.empty interp.
Proof.
intros.
unfold sp_ok.
intros p Hp.
rewrite SPWEqP.MP.Dec.F.empty_b in Hp.
discriminate.
Qed.

Lemma collect_cols : 
  forall (A B C : COLTpoint) (HCol : CTCol A B C) pa pb pc ss (interp :  positive -> COLTpoint),
  interp pa = A ->
  interp pb = B ->
  interp pc = C ->
  ss_ok ss interp -> ss_ok (SS.add (S.add pa (S.add pb (S.add pc S.empty))) ss) interp.
Proof.
intros A B C HCol pa pb pc ss interp HA HB HC HSS.
unfold ss_ok.
intros s Hs.
intros p1 p2 p3 Hmem.
apply SSWEqP.MP.Dec.F.mem_2 in Hs.
apply SSWEqP.MP.Dec.F.add_iff in Hs.
do 2 (rewrite andb_true_iff in Hmem).
destruct Hmem as [[Hmem1 Hmem2] Hmem3].
elim Hs; intro HsE.

  assert (HmemR : forall p, S.mem p (S.add pa (S.add pb (S.add pc S.empty))) = S.mem p s)
    by (intros; apply SWP.Dec.F.mem_m; auto).
  rewrite <- HmemR in Hmem1.
  rewrite <- HmemR in Hmem2.
  rewrite <- HmemR in Hmem3.
  clear HmemR.
  elim (Pos.eq_dec pa p1); intro Hpap1.

    rewrite Hpap1 in *; rewrite HA.
    elim (Pos.eq_dec p1 p2); intro Hp1p2.

      rewrite Hp1p2 in *; rewrite HA.
      apply CTcol_trivial_1.

      rewrite SWP.Dec.F.add_neq_b in Hmem2.
      elim (Pos.eq_dec pb p2); intro Hpbp2.

        rewrite Hpbp2 in *; rewrite HB.
        elim (Pos.eq_dec p3 p1); intro Hp3p1; elim (Pos.eq_dec p3 p2); intro Hp3p2.

          rewrite Hp3p2; rewrite HB; apply CTcol_trivial_2.

          rewrite Hp3p1; rewrite HA; apply CTcol_permutation_1; apply CTcol_trivial_1.

          rewrite Hp3p2; rewrite HB; apply CTcol_trivial_2.

          do 2 (rewrite SWP.Dec.F.add_neq_b in Hmem3).
          rewrite <- SWP.singleton_equal_add in Hmem3.
          apply SWP.Dec.F.mem_iff in Hmem3.
          apply SWP.Dec.F.singleton_1 in Hmem3.
          rewrite <- Hmem3; rewrite HC; assumption.
          intuition.
          intuition.
          intuition.

        rewrite SWP.Dec.F.add_neq_b in Hmem2.
        rewrite <- SWP.singleton_equal_add in Hmem2.
        apply SWP.Dec.F.mem_iff in Hmem2.
        apply SWP.Dec.F.singleton_1 in Hmem2.
        rewrite <- Hmem2 in *; rewrite HC.
        elim (Pos.eq_dec p3 p1); intro Hp3p1; elim (Pos.eq_dec p3 p2); intro Hp3p2.

          rewrite Hp3p2 in *; rewrite Hmem2 in *; rewrite HC; apply CTcol_trivial_2.

          rewrite Hp3p1 in *; rewrite HA; apply CTcol_permutation_1; apply CTcol_trivial_1.

          rewrite Hp3p2 in *; rewrite Hmem2 in *; rewrite HC; apply CTcol_trivial_2.

          rewrite SWP.Dec.F.add_neq_b in Hmem3.
          elim (Pos.eq_dec p3 pb); intro Hp3pb.

            rewrite Hp3pb in *; rewrite HB; apply CTcol_permutation_5; assumption.

            rewrite SWP.Dec.F.add_neq_b in Hmem3.
            rewrite <- SWP.singleton_equal_add in Hmem3.
            apply SWP.Dec.F.mem_iff in Hmem3.
            apply SWP.Dec.F.singleton_1 in Hmem3.
            rewrite Hmem3 in *; contradiction.
            intuition.

          intuition.

        intuition.

      intuition.

    rewrite SWP.Dec.F.add_neq_b in Hmem1.
    elim (Pos.eq_dec p1 pb); intro Hp1pb.

      rewrite Hp1pb in *; rewrite HB.
      elim (Pos.eq_dec pa p2); intro Hpap2.

        rewrite Hpap2 in *; rewrite HA.
        elim (Pos.eq_dec p3 p2); intro Hp3p2; elim (Pos.eq_dec p3 pb); intro Hp3pb.

          rewrite Hp3pb; rewrite HB; apply CTcol_permutation_1; apply CTcol_trivial_1.

          rewrite Hp3p2; rewrite HA; apply CTcol_trivial_2.

          rewrite Hp3pb; rewrite HB; apply CTcol_permutation_1; apply CTcol_trivial_1.

          do 2 (rewrite SWP.Dec.F.add_neq_b in Hmem3).
          rewrite <- SWP.singleton_equal_add in Hmem3.
          apply SWP.Dec.F.mem_iff in Hmem3.
          apply SWP.Dec.F.singleton_1 in Hmem3.
          rewrite <- Hmem3; rewrite HC; apply CTcol_permutation_4; assumption.
          intuition.
          intuition.
          intuition.

        rewrite SWP.Dec.F.add_neq_b in Hmem2.
        elim (Pos.eq_dec p2 pb); intro Hp2pb.

          rewrite Hp2pb; rewrite HB; apply CTcol_trivial_1.

          rewrite SWP.Dec.F.add_neq_b in Hmem2.
          rewrite <- SWP.singleton_equal_add in Hmem2.
          apply SWP.Dec.F.mem_iff in Hmem2.
          apply SWP.Dec.F.singleton_1 in Hmem2.
          rewrite <- Hmem2 in *; rewrite HC.
          elim (Pos.eq_dec p3 p1); intro Hp3p1; elim (Pos.eq_dec p3 p2); intro Hp3p2.

            rewrite Hp3p2 in *; rewrite Hmem2 in *; rewrite HC; apply CTcol_trivial_2.

            rewrite Hp3p1 in *; rewrite Hp1pb; rewrite HB; apply CTcol_permutation_1; apply CTcol_trivial_1.

            rewrite Hp3p2 in *; rewrite Hmem2 in *; rewrite HC; apply CTcol_trivial_2.

            elim (Pos.eq_dec p3 pa); intro Hp3pa.

              rewrite Hp3pa; rewrite HA; apply CTcol_permutation_1; assumption.

              rewrite SWP.Dec.F.add_neq_b in Hmem3.
              elim (Pos.eq_dec p3 pb); intro Hp3pb.

                rewrite Hp3pb in *; rewrite HB; apply CTcol_permutation_5; apply CTcol_trivial_1.

                rewrite SWP.Dec.F.add_neq_b in Hmem3.
                rewrite <- SWP.singleton_equal_add in Hmem3.
                apply SWP.Dec.F.mem_iff in Hmem3.
                apply SWP.Dec.F.singleton_1 in Hmem3.
                rewrite Hmem3 in *; contradiction.
                intuition.

              intuition.

          intuition.

        intuition.

      rewrite SWP.Dec.F.add_neq_b in Hmem1.
      rewrite <- SWP.singleton_equal_add in Hmem1.
      apply SWP.Dec.F.mem_iff in Hmem1.
      apply SWP.Dec.F.singleton_1 in Hmem1.
      rewrite <- Hmem1 in *; rewrite HC.
      elim (Pos.eq_dec pa p2); intro Hpap2.

        rewrite Hpap2 in *; rewrite HA.
        elim (Pos.eq_dec p3 p2); intro Hp3p2; elim (Pos.eq_dec p3 pb); intro Hp3pb.

          rewrite Hp3pb; rewrite HB; apply CTcol_permutation_2; assumption.

          rewrite Hp3p2; rewrite HA; apply CTcol_trivial_2.

          rewrite Hp3pb; rewrite HB; apply CTcol_permutation_2; assumption.

          do 2 (rewrite SWP.Dec.F.add_neq_b in Hmem3).
          rewrite <- SWP.singleton_equal_add in Hmem3.
          apply SWP.Dec.F.mem_iff in Hmem3.
          apply SWP.Dec.F.singleton_1 in Hmem3.
          rewrite <- Hmem3; rewrite HC; apply CTcol_permutation_1; apply CTcol_trivial_1.
          intuition.
          intuition.
          intuition.

        rewrite SWP.Dec.F.add_neq_b in Hmem2.
        elim (Pos.eq_dec p2 pb); intro Hp2pb.

          rewrite Hp2pb; rewrite HB.
          elim (Pos.eq_dec p3 pa); intro Hp3pa; elim (Pos.eq_dec p3 pb); intro Hp3pb.

            rewrite Hp3pa; rewrite HA; apply CTcol_permutation_3; assumption.

            rewrite Hp3pa; rewrite HA; apply CTcol_permutation_3; assumption.

            rewrite Hp3pb; rewrite HB; apply CTcol_trivial_2.

            do 2 (rewrite SWP.Dec.F.add_neq_b in Hmem3).
            rewrite <- SWP.singleton_equal_add in Hmem3.
            apply SWP.Dec.F.mem_iff in Hmem3.
            apply SWP.Dec.F.singleton_1 in Hmem3.
            rewrite <- Hmem3 in *; rewrite HC; apply CTcol_permutation_1; apply CTcol_trivial_1.
            intuition.

          intuition.

        intuition.

        rewrite SWP.Dec.F.add_neq_b in Hmem2.
        rewrite <- SWP.singleton_equal_add in Hmem2.
        apply SWP.Dec.F.mem_iff in Hmem2.
        apply SWP.Dec.F.singleton_1 in Hmem2.
        rewrite <- Hmem2 in *; rewrite HC; apply CTcol_trivial_1.
        intuition.

        intuition.

      intuition.

    intuition.

  unfold ss_ok in *.
  apply HSS with s.
  apply SSWEqP.MP.Dec.F.mem_1.
  assumption.
  rewrite Hmem1; rewrite Hmem2; rewrite Hmem3; reflexivity.
Qed.

Lemma collect_diffs : 
  forall (A B : COLTpoint) (H : A <> B) pa pb sp (interp :  positive -> COLTpoint),
  interp pa = A ->
  interp pb = B ->
  sp_ok sp interp -> sp_ok (SP.add (pa, pb) sp) interp.
Proof.
intros A B HDiff pa pb sp interp HA HB HSP.
unfold sp_ok.
intros p Hp.
apply SPWEqP.MP.Dec.F.mem_2 in Hp.
apply SPWEqP.MP.Dec.F.add_iff in Hp.
elim Hp; intro HpE.

  destruct HpE as [HEq1 HEq2].
  destruct p as [fstp sndp].
  simpl in *.
  elim (Pos.min_spec pa pb); intro Hmin1; elim (Pos.min_spec fstp sndp); intro Hmin2;
  destruct Hmin1 as [Hpapb1 Hmin1]; destruct Hmin2 as [Hfpsp1 Hmin2];
  elim (Pos.max_spec pa pb); intro Hmax1; elim (Pos.max_spec fstp sndp); intro Hmax2;
  destruct Hmax1 as [Hpapb2 Hmax1]; destruct Hmax2 as [Hfpsp2 Hmax2].

    rewrite Hmin1 in *; rewrite Hmin2 in *; rewrite Hmax1 in *;rewrite Hmax2 in *.
    rewrite <- HEq1; rewrite <- HEq2; rewrite HA in *; rewrite HB in *; assumption.

    rewrite <- Pos.ltb_lt in Hfpsp1; rewrite Pos.ltb_antisym in Hfpsp1;
    rewrite negb_true_iff in Hfpsp1; rewrite Pos.leb_nle in Hfpsp1; contradiction.

    rewrite <- Pos.ltb_lt in Hpapb1; rewrite Pos.ltb_antisym in Hpapb1;
    rewrite negb_true_iff in Hpapb1; rewrite Pos.leb_nle in Hpapb1; contradiction.

    rewrite <- Pos.ltb_lt in Hfpsp1; rewrite Pos.ltb_antisym in Hfpsp1;
    rewrite negb_true_iff in Hfpsp1; rewrite Pos.leb_nle in Hfpsp1; contradiction.

    rewrite <- Pos.ltb_lt in Hfpsp2; rewrite Pos.ltb_antisym in Hfpsp2;
    rewrite negb_true_iff in Hfpsp2; rewrite Pos.leb_nle in Hfpsp2; contradiction.

    rewrite Hmin1 in *; rewrite Hmin2 in *; rewrite Hmax1 in *;rewrite Hmax2 in *.
    rewrite <- HEq1; rewrite <- HEq2; rewrite HA in *; rewrite HB in *; assumption.

    rewrite <- Pos.ltb_lt in Hfpsp2; rewrite Pos.ltb_antisym in Hfpsp2;
    rewrite negb_true_iff in Hfpsp2; rewrite Pos.leb_nle in Hfpsp2; contradiction.

    rewrite <- Pos.ltb_lt in Hpapb1; rewrite Pos.ltb_antisym in Hpapb1;
    rewrite negb_true_iff in Hpapb1; rewrite Pos.leb_nle in Hpapb1; contradiction.

    rewrite <- Pos.ltb_lt in Hpapb2; rewrite Pos.ltb_antisym in Hpapb2;
    rewrite negb_true_iff in Hpapb2; rewrite Pos.leb_nle in Hpapb2; contradiction.

    rewrite <- Pos.ltb_lt in Hpapb2; rewrite Pos.ltb_antisym in Hpapb2;
    rewrite negb_true_iff in Hpapb2; rewrite Pos.leb_nle in Hpapb2; contradiction.

    rewrite Hmin1 in *; rewrite Hmin2 in *; rewrite Hmax1 in *;rewrite Hmax2 in *.
    rewrite <- HEq1; rewrite <- HEq2; rewrite HA in *; rewrite HB in *; intuition.

    rewrite <- Pos.ltb_lt in Hfpsp1; rewrite Pos.ltb_antisym in Hfpsp1;
    rewrite negb_true_iff in Hfpsp1; rewrite Pos.leb_nle in Hfpsp1; contradiction.

    rewrite <- Pos.ltb_lt in Hpapb2; rewrite Pos.ltb_antisym in Hpapb2;
    rewrite negb_true_iff in Hpapb2; rewrite Pos.leb_nle in Hpapb2; contradiction.

    rewrite <- Pos.ltb_lt in Hpapb2; rewrite Pos.ltb_antisym in Hpapb2;
    rewrite negb_true_iff in Hpapb2; rewrite Pos.leb_nle in Hpapb2; contradiction.

    rewrite <- Pos.ltb_lt in Hfpsp2; rewrite Pos.ltb_antisym in Hfpsp2;
    rewrite negb_true_iff in Hfpsp2; rewrite Pos.leb_nle in Hfpsp2; contradiction.

    rewrite Hmin1 in *; rewrite Hmin2 in *; rewrite Hmax1 in *;rewrite Hmax2 in *.
    rewrite <- HEq1; rewrite <- HEq2; rewrite HA in *; rewrite HB in *; intuition.

  unfold sp_ok in *.
  apply HSP.
  apply SPWEqP.MP.Dec.F.mem_1.
  assumption.
Qed.

Definition list_assoc_inv :=
  (fix list_assoc_inv_rec (A:Type) (B:Set)
                          (eq_dec:forall e1 e2:B, {e1 = e2} + {e1 <> e2})
                          (lst : list (prodT A B)) {struct lst} : B -> A -> A :=
  fun (key:B) (default:A) =>
    match lst with
      | nil => default
      | cons (pairT v e) l =>
        match eq_dec e key with
          | left _ => v
          | right _ => list_assoc_inv_rec A B eq_dec l key default
        end
    end).

Lemma positive_dec : forall (p1 p2:positive), {p1=p2}+{~p1=p2}.
Proof.
decide equality.
Defined.

Definition interp (lvar : list (COLTpoint * positive)) (Default : COLTpoint) : positive -> COLTpoint := 
  fun p => list_assoc_inv COLTpoint positive positive_dec lvar p Default.

Definition Col_tagged A B C := CTCol A B C.

Lemma Col_Col_tagged : forall A B C, CTCol A B C -> Col_tagged A B C.
Proof.
trivial.
Qed.

Lemma Col_tagged_Col : forall A B C, Col_tagged A B C -> CTCol A B C.
Proof.
trivial.
Qed.

Definition Diff_tagged (A B: COLTpoint) := A <> B.

Lemma Diff_Diff_tagged : forall A B , A <> B -> Diff_tagged A B.
Proof.
trivial.
Qed.

Lemma Diff_tagged_Diff : forall A B , Diff_tagged A B -> A <> B.
Proof.
trivial.
Qed.

Definition eq_tagged (lvar : list (COLTpoint * positive)) := lvar = lvar.

Lemma eq_eq_tagged : forall lvar, lvar = lvar -> eq_tagged lvar.
Proof.
trivial.
Qed.

Definition partition_ss e ss :=
  SS.partition (fun s => S.mem e s) ss.

Definition fst_ss (pair : SS.t * SS.t) :=
 match pair with
    |(a,b) => a
  end.

Definition snd_ss (pair : SS.t * SS.t) :=
 match pair with
    |(a,b) => b
  end.

Definition subst_in_set p1 p2 s := S.add p1 (S.remove p2 s).

Definition subst_in_ss_aux p1 p2 := (fun s ss => SS.add (subst_in_set p1 p2 s) ss).

Definition subst_in_ss p1 p2 ss :=
  let pair := partition_ss p2 ss in
  let fss := fst_ss(pair) in
  let sss := snd_ss(pair) in
  let newfss := SS.fold (subst_in_ss_aux p1 p2) fss SS.empty in
  SS.union newfss sss.

Lemma proper_4 : forall p, Proper (S.Equal ==> eq) (fun s : SS.elt => S.mem p s).
Proof.
intros p x y Hxy.
apply SWP.Dec.F.mem_m; intuition.
Qed.

Lemma proper_5 : forall p, Proper (S.Equal ==> eq) (fun s : SS.elt => negb (S.mem p s)).
Proof.
intros p x y Hxy.
apply negb_sym.
rewrite negb_involutive.
apply SWP.Dec.F.mem_m; intuition.
Qed.

Lemma subst_ss_ok :
  forall (A B : COLTpoint) (H : A = B) pa pb ss (interp :  positive -> COLTpoint),
  interp pa = A ->
  interp pb = B ->
  ss_ok ss interp -> ss_ok (subst_in_ss pa pb ss) interp.
Proof.
intros A B H pa pb ss interp HA HB HSS.
unfold subst_in_ss.
unfold ss_ok.
intros s Hs.
intros p1 p2 p3 Hmem.
apply SSWEqP.MP.Dec.F.mem_2 in Hs.
rewrite SSWEqP.MP.Dec.F.union_iff in Hs.
elim Hs; intro HIn; clear Hs.

  assert (HSSF : ss_ok (fst_ss (partition_ss pb ss)) interp).

    clear Hmem; clear p1; clear p2; clear p3.
    intros s' Hs'.
    intros.
    apply SSWEqP.MP.Dec.F.mem_2 in Hs'.
    unfold partition in Hs'.
    apply SS.partition_spec1 in Hs'; try apply proper_4.
    apply SSWEqP.MP.Dec.F.filter_1 in Hs'; try apply proper_4.
    unfold ss_ok in HSS.
    apply HSS with s'; try assumption.
    apply SSWEqP.MP.Dec.F.mem_1; assumption.

  assert (HSSF' : ss_ok (SS.fold (subst_in_ss_aux pa pb) (fst_ss (partition_ss pb ss)) SS.empty) interp).

    apply SSWEqP.MP.fold_rec_nodep; try apply ss_ok_empty.
    intros x a HIn1 HSSa.
    clear Hmem; clear p1; clear p2; clear p3.
    intros s' Hs'.
    intros p1 p2 p3 Hmem.
    unfold subst_in_ss_aux in *.
    apply SSWEqP.MP.Dec.F.mem_2 in Hs'.
    rewrite SSWEqP.MP.Dec.F.add_iff in Hs'.
    elim Hs'; intro HIn2; clear Hs'.

      unfold subst_in_set in HIn2.
      clear HIn; clear s; assert (HEq := HIn2); clear HIn2; assert (HIn := HIn1); clear HIn1.
      elim (Pos.eq_dec pb p1); intro Hp1; elim (Pos.eq_dec pb p2); intro Hp2; elim (Pos.eq_dec pb p3); intro Hp3.

        do 2 subst.
        apply CTcol_trivial_1.

        do 2 subst.
        apply CTcol_trivial_1.

        do 2 subst.
        apply CTcol_permutation_4; apply CTcol_trivial_2.

        subst.
        do 2 (rewrite andb_true_iff in Hmem).
        destruct Hmem as [[Hmem1' Hmem2'] Hmem3'].
        assert (Hmem1 : S.mem p1 x = true).

          unfold partition in HIn.
          apply SS.partition_spec1 in HIn; try apply proper_4.
          apply SSWEqP.MP.Dec.F.filter_2 in HIn; try assumption; apply proper_4.

        elim (Pos.eq_dec pa p2); intro Hpap2.

          subst; rewrite HB; apply CTcol_trivial_1.

          assert (Hmem2 : S.mem p2 x = true).

            rewrite <- HEq in Hmem2'.
            rewrite SWP.Dec.F.add_neq_b in Hmem2'; try assumption.
            rewrite SWP.Dec.F.remove_neq_b in Hmem2'; assumption.

          elim (Pos.eq_dec pa p3); intro Hpap3.

            subst; rewrite HB; apply CTcol_permutation_4; apply CTcol_trivial_2.

            assert (Hmem3 : S.mem p3 x = true).

              rewrite <- HEq in Hmem3'.
              rewrite SWP.Dec.F.add_neq_b in Hmem3'; try assumption.
              rewrite SWP.Dec.F.remove_neq_b in Hmem3'; assumption.

            unfold ss_ok in HSSF.
            apply HSSF with x.

              apply SSWEqP.MP.Dec.F.mem_1; assumption.

              do 2 (rewrite andb_true_iff); repeat split; assumption.

        do 2 subst.
        apply CTcol_trivial_2.

        subst.
        do 2 (rewrite andb_true_iff in Hmem).
        destruct Hmem as [[Hmem1' Hmem2'] Hmem3'].
        assert (Hmem2 : S.mem p2 x = true).

          unfold partition in HIn.
          apply SS.partition_spec1 in HIn; try apply proper_4.
          apply SSWEqP.MP.Dec.F.filter_2 in HIn; try assumption; apply proper_4.

        elim (Pos.eq_dec pa p1); intro Hpap1.

          subst; rewrite HB; apply CTcol_trivial_1.

          assert (Hmem1 : S.mem p1 x = true).

            rewrite <- HEq in Hmem1'.
            rewrite SWP.Dec.F.add_neq_b in Hmem1'; try assumption.
            rewrite SWP.Dec.F.remove_neq_b in Hmem1'; assumption.

          elim (Pos.eq_dec pa p3); intro Hpap3.

            subst; rewrite HB; apply CTcol_trivial_2.

            assert (Hmem3 : S.mem p3 x = true).

              rewrite <- HEq in Hmem3'.
              rewrite SWP.Dec.F.add_neq_b in Hmem3'; try assumption.
              rewrite SWP.Dec.F.remove_neq_b in Hmem3'; assumption.

            unfold ss_ok in HSSF.
            apply HSSF with x.

              apply SSWEqP.MP.Dec.F.mem_1; assumption.

              do 2 (rewrite andb_true_iff); repeat split; assumption.

        subst.
        do 2 (rewrite andb_true_iff in Hmem).
        destruct Hmem as [[Hmem1' Hmem2'] Hmem3'].
        assert (Hmem3 : S.mem p3 x = true).

          unfold partition in HIn.
          apply SS.partition_spec1 in HIn; try apply proper_4.
          apply SSWEqP.MP.Dec.F.filter_2 in HIn; try assumption; apply proper_4.

        elim (Pos.eq_dec pa p1); intro Hpap1.

          subst; rewrite HB; apply CTcol_permutation_4; apply CTcol_trivial_2.

          assert (Hmem1 : S.mem p1 x = true).

            rewrite <- HEq in Hmem1'.
            rewrite SWP.Dec.F.add_neq_b in Hmem1'; try assumption.
            rewrite SWP.Dec.F.remove_neq_b in Hmem1'; assumption.

          elim (Pos.eq_dec pa p2); intro Hpap2.

            subst; rewrite HB; apply CTcol_trivial_2.

            assert (Hmem2 : S.mem p2 x = true).

              rewrite <- HEq in Hmem2'.
              rewrite SWP.Dec.F.add_neq_b in Hmem2'; try assumption.
              rewrite SWP.Dec.F.remove_neq_b in Hmem2'; assumption.

            unfold ss_ok in HSSF.
            apply HSSF with x.

              apply SSWEqP.MP.Dec.F.mem_1; assumption.

              do 2 (rewrite andb_true_iff); repeat split; assumption.

        do 2 (rewrite andb_true_iff in Hmem).
        destruct Hmem as [[Hmem1' Hmem2'] Hmem3'].

        elim (Pos.eq_dec pa p1); intro Hpap1;
        elim (Pos.eq_dec pa p2); intro Hpap2;
        elim (Pos.eq_dec pa p3); intro Hpap3.

          do 2 subst; apply CTcol_trivial_1.

          do 2 subst; apply CTcol_trivial_1.

          do 2 subst; apply CTcol_permutation_4; apply CTcol_trivial_2.

          subst.
          assert (Hmem1 : S.mem pb x = true).

            unfold partition in HIn.
            apply SS.partition_spec1 in HIn; try apply proper_4.
            apply SSWEqP.MP.Dec.F.filter_2 in HIn; try assumption; apply proper_4.

          assert (Hmem2 : S.mem p2 x = true).

            rewrite <- HEq in Hmem2'.
            rewrite SWP.Dec.F.add_neq_b in Hmem2'; try assumption.
            rewrite SWP.Dec.F.remove_neq_b in Hmem2'; assumption.

          assert (Hmem3 : S.mem p3 x = true).

            rewrite <- HEq in Hmem3'.
            rewrite SWP.Dec.F.add_neq_b in Hmem3'; try assumption.
            rewrite SWP.Dec.F.remove_neq_b in Hmem3'; assumption.

          rewrite <- HB.
          unfold ss_ok in HSSF.
          apply HSSF with x.

            apply SSWEqP.MP.Dec.F.mem_1; assumption.

            do 2 (rewrite andb_true_iff); repeat split; assumption.

          do 2 subst; apply CTcol_trivial_2.

          subst.
          assert (Hmem2 : S.mem pb x = true).

            unfold partition in HIn.
            apply SS.partition_spec1 in HIn; try apply proper_4.
            apply SSWEqP.MP.Dec.F.filter_2 in HIn; try assumption; apply proper_4.

          assert (Hmem1 : S.mem p1 x = true).

            rewrite <- HEq in Hmem1'.
            rewrite SWP.Dec.F.add_neq_b in Hmem1'; try assumption.
            rewrite SWP.Dec.F.remove_neq_b in Hmem1'; assumption.

          assert (Hmem3 : S.mem p3 x = true).

            rewrite <- HEq in Hmem3'.
            rewrite SWP.Dec.F.add_neq_b in Hmem3'; try assumption.
            rewrite SWP.Dec.F.remove_neq_b in Hmem3'; assumption.

          rewrite <- HB.
          unfold ss_ok in HSSF.
          apply HSSF with x.

            apply SSWEqP.MP.Dec.F.mem_1; assumption.

            do 2 (rewrite andb_true_iff); repeat split; assumption.

          subst.
          assert (Hmem3 : S.mem pb x = true).

            unfold partition in HIn.
            apply SS.partition_spec1 in HIn; try apply proper_4.
            apply SSWEqP.MP.Dec.F.filter_2 in HIn; try assumption; apply proper_4.

          assert (Hmem1 : S.mem p1 x = true).

            rewrite <- HEq in Hmem1'.
            rewrite SWP.Dec.F.add_neq_b in Hmem1'; try assumption.
            rewrite SWP.Dec.F.remove_neq_b in Hmem1'; assumption.

          assert (Hmem2 : S.mem p2 x = true).

            rewrite <- HEq in Hmem2'.
            rewrite SWP.Dec.F.add_neq_b in Hmem2'; try assumption.
            rewrite SWP.Dec.F.remove_neq_b in Hmem2'; assumption.

          rewrite <- HB.
          unfold ss_ok in HSSF.
          apply HSSF with x.

            apply SSWEqP.MP.Dec.F.mem_1; assumption.

            do 2 (rewrite andb_true_iff); repeat split; assumption.

         assert (Hmem1 : S.mem p1 x = true).

            rewrite <- HEq in Hmem1'.
            rewrite SWP.Dec.F.add_neq_b in Hmem1'; try assumption.
            rewrite SWP.Dec.F.remove_neq_b in Hmem1'; assumption.

          assert (Hmem2 : S.mem p2 x = true).

            rewrite <- HEq in Hmem2'.
            rewrite SWP.Dec.F.add_neq_b in Hmem2'; try assumption.
            rewrite SWP.Dec.F.remove_neq_b in Hmem2'; assumption.

          assert (Hmem3 : S.mem p3 x = true).

            rewrite <- HEq in Hmem3'.
            rewrite SWP.Dec.F.add_neq_b in Hmem3'; try assumption.
            rewrite SWP.Dec.F.remove_neq_b in Hmem3'; assumption.

          unfold ss_ok in HSSF.
          apply HSSF with x.

            apply SSWEqP.MP.Dec.F.mem_1; assumption.

            do 2 (rewrite andb_true_iff); repeat split; assumption.

      unfold ss_ok in HSSa.
      apply HSSa with s'; try assumption.
      apply SSWEqP.MP.Dec.F.mem_1; assumption.

  clear HSSF; assert (HSSF := HSSF'); clear HSSF'.

  unfold ss_ok in HSSF.
  apply HSSF with s; try assumption.
  apply SSWEqP.MP.Dec.F.mem_1; assumption.

  assert (HSSS : ss_ok (snd_ss (partition_ss pb ss)) interp).

    clear Hmem; clear p1; clear p2; clear p3.
    intros s' Hs'.
    intros.
    apply SSWEqP.MP.Dec.F.mem_2 in Hs'.
    unfold partition in Hs'.
    apply SS.partition_spec2 in Hs'; try apply proper_4.
    apply SSWEqP.MP.Dec.F.filter_1 in Hs'; try apply proper_5.
    unfold ss_ok in HSS.
    apply HSS with s'; try assumption.
    apply SSWEqP.MP.Dec.F.mem_1; assumption.

  unfold ss_ok in HSSS.
  apply HSSS with s; try assumption.
  apply SSWEqP.MP.Dec.F.mem_1; assumption.
Qed.

Definition partition_sp_1 p sp :=
  SP.partition (fun e => Pos.eqb (fstpp e) p || Pos.eqb (sndpp e) p) sp.

Definition partition_sp_2 p sp :=
  SP.partition (fun e => Pos.eqb (fstpp e) p) sp.

Definition fst_sp (pair : SP.t * SP.t) :=
 match pair with
    |(a,b) => a
  end.

Definition snd_sp (pair : SP.t * SP.t) :=
 match pair with
    |(a,b) => b
  end.

Definition new_pair_1 pair (pos : positive) := (pos, sndpp(pair)).

Definition new_pair_2 pair (pos : positive) := (fstpp(pair), pos).

Definition subst_in_sp_aux_1 := (fun pos pair sp => SP.add (new_pair_1 pair pos) sp).

Definition subst_in_sp_aux_2 := (fun pos pair sp => SP.add (new_pair_2 pair pos) sp).

Definition subst_in_sp p1 p2 sp :=
  let pair_1 := partition_sp_1 p2 sp in
  let sp_to_modify := fst_sp(pair_1) in
  let sp_to_keep := snd_sp(pair_1) in
  let pair_2 := partition_sp_2 p2 sp_to_modify in
  let sp_to_modify_f := fst_sp(pair_2) in
  let sp_to_modify_s := snd_sp(pair_2) in
  let newsp_to_modify_f := SP.fold (subst_in_sp_aux_1 p1) sp_to_modify_f SP.empty in
  let newsp_to_modify_s := SP.fold (subst_in_sp_aux_2 p1) sp_to_modify_s SP.empty in
  SP.union (SP.union newsp_to_modify_f newsp_to_modify_s) sp_to_keep.

Lemma proper_6 : forall p, Proper ((fun t1 t2 : SetOfPairsOfPositiveOrderedType.t =>
                                  Pos.eq (fstpp t1) (fstpp t2) /\ Pos.eq (sndpp t1) (sndpp t2)) ==> eq)
                                  (fun e : SP.elt => (fstpp e =? p)%positive || (sndpp e =? p)%positive).
Proof.
intros p x y Hxy.
destruct Hxy as [Hxyf Hxys].
rewrite Hxyf; rewrite Hxys.
reflexivity.
Qed.

Lemma proper_7 : forall p, Proper ((fun t1 t2 : SetOfPairsOfPositiveOrderedType.t =>
                                  Pos.eq (fstpp t1) (fstpp t2) /\ Pos.eq (sndpp t1) (sndpp t2)) ==> eq)
                                  (fun x : SP.elt => negb ((fstpp x =? p)%positive || (sndpp x =? p)%positive)).
Proof.
intros p x y Hxy.
destruct Hxy as [Hxyf Hxys].
rewrite Hxyf; rewrite Hxys.
reflexivity.
Qed.

Lemma proper_8 : forall p, Proper ((fun t1 t2 : SetOfPairsOfPositiveOrderedType.t =>
                                  Pos.eq (fstpp t1) (fstpp t2) /\ Pos.eq (sndpp t1) (sndpp t2)) ==> eq)
                                  (fun e : SP.elt => (fstpp e =? p)%positive).
Proof.
intros p x y Hxy.
destruct Hxy as [Hxyf Hxys].
rewrite Hxyf.
reflexivity.
Qed.

Lemma proper_9 : forall p, Proper ((fun t1 t2 : SetOfPairsOfPositiveOrderedType.t =>
                                  Pos.eq (fstpp t1) (fstpp t2) /\ Pos.eq (sndpp t1) (sndpp t2)) ==> eq)
                                  (fun x : SP.elt => negb (fstpp x =? p)%positive).
Proof.
intros p x y Hxy.
destruct Hxy as [Hxyf Hxys].
rewrite Hxyf.
reflexivity.
Qed.

Lemma subst_sp_ok :
  forall (A B : COLTpoint) (H : A = B) pa pb sp (interp :  positive -> COLTpoint),
  interp pa = A ->
  interp pb = B ->
  sp_ok sp interp -> sp_ok (subst_in_sp pa pb sp) interp.
Proof.
intros A B H pa pb sp interp HA HB HSP.
unfold subst_in_sp.
unfold sp_ok.
intros p Hp.
apply SPWEqP.MP.Dec.F.mem_2 in Hp.
do 2 rewrite SPWEqP.MP.Dec.F.union_iff in Hp.
elim Hp; intro HInAux; clear Hp.

  assert (HSPM : sp_ok (fst_sp (partition_sp_1 pb sp)) interp).

    intros p' Hp'.
    apply SPWEqP.MP.Dec.F.mem_2 in Hp'.
    unfold partition_sp_1 in Hp'.
    apply SP.partition_spec1 in Hp'; try apply proper_6.
    apply SPWEqP.MP.Dec.F.filter_1 in Hp'; try apply proper_6.
    unfold sp_ok in HSP.
    apply HSP; try assumption.
    apply SPWEqP.MP.Dec.F.mem_1; assumption.

  clear HSP.
  elim HInAux; intro HIn; clear HInAux.

    assert (HSPF : sp_ok (fst_sp (partition_sp_2 pb (fst_sp (partition_sp_1 pb sp)))) interp).

      intros p' Hp'.
      apply SPWEqP.MP.Dec.F.mem_2 in Hp'.
      unfold partition_sp_1 in Hp'.
      apply SP.partition_spec1 in Hp'; try apply proper_8.
      apply SPWEqP.MP.Dec.F.filter_1 in Hp'; try apply proper_8.
      unfold sp_ok in HSPM.
      apply HSPM; try assumption.
      apply SPWEqP.MP.Dec.F.mem_1; assumption.

    clear HSPM.

    assert (HSPF' : sp_ok (SP.fold (subst_in_sp_aux_1 pa)
                         (fst_sp (partition_sp_2 pb (fst_sp (partition_sp_1 pb sp))))
                         SP.empty) interp).
    apply SPWEqP.MP.fold_rec_nodep; try apply sp_ok_empty.
    clear HIn.
    intros x a HInRec HSPRec.
    intros p' Hp'.
    unfold subst_in_sp_aux_1 in *.
    apply SPWEqP.MP.Dec.F.mem_2 in Hp'.
    rewrite SPWEqP.MP.Dec.F.add_iff in Hp'.
    elim Hp'; intro HIn; clear Hp'.

      destruct HIn as [HEq1 HEq2].
      rewrite <- HEq1; rewrite <- HEq2.
      unfold new_pair_1.
      clear HSPRec; clear a.
      elim (Pos.min_spec pa (sndpp(x))); intro Hmin.

        destruct Hmin as [HLt Hmin].
        assert (Hmax : Pos.max pa (sndpp(x)) = (sndpp(x))) by (apply Pos.max_r; apply Pos.lt_le_incl; assumption).
        assert (HF : fstpp(pa, sndpp(x)) = pa) by (unfold fstpp; assumption).
        assert (HS : sndpp(pa, sndpp(x)) = sndpp(x)) by (unfold sndpp; assumption).
        rewrite HF; rewrite HS.

        assert (Hpb : fstpp(x) = pb).

          unfold partition_sp_2 in HInRec.
          apply SP.partition_spec1 in HInRec; try apply proper_8.
          apply SPWEqP.MP.Dec.F.filter_2 in HInRec; try apply proper_8.
          apply Ndec.Peqb_complete.
          assumption.

        intro HEq4.
        unfold sp_ok in HSPF.
        apply SPWEqP.MP.Dec.F.mem_1 in HInRec.
        apply (HSPF x) in HInRec.
        apply HInRec.
        rewrite Hpb; rewrite <- HEq4; rewrite HA; rewrite HB; rewrite H; reflexivity.

        destruct Hmin as [HLe Hmin].
        assert (Hmax : Pos.max pa (sndpp(x)) = pa) by (apply Pos.max_l; assumption).
        assert (HF : fstpp(pa, sndpp(x)) = sndpp(x)) by (unfold fstpp; assumption).
        assert (HS : sndpp(pa, sndpp(x)) = pa) by (unfold sndpp; assumption).
        rewrite HF; rewrite HS.

        assert (Hpb : fstpp(x) = pb).

          unfold partition_sp_2 in HInRec.
          apply SP.partition_spec1 in HInRec; try apply proper_8.
          apply SPWEqP.MP.Dec.F.filter_2 in HInRec; try apply proper_8.
          apply Ndec.Peqb_complete.
          assumption.

        intro HEq4.
        unfold sp_ok in HSPF.
        apply SPWEqP.MP.Dec.F.mem_1 in HInRec.
        apply (HSPF x) in HInRec.
        apply HInRec.
        rewrite Hpb; rewrite HEq4; rewrite HA; rewrite HB; rewrite H; reflexivity.

      unfold sp_ok in HSPRec.
      apply HSPRec.
      apply SPWEqP.MP.Dec.F.mem_1; assumption.

    clear HSPF; assert (HSPF := HSPF'); clear HSPF'.
    unfold sp_ok in HSPF.
    apply HSPF.
    apply SPWEqP.MP.Dec.F.mem_1; assumption.

    assert (HSPS : sp_ok (snd_sp (partition_sp_2 pb (fst_sp (partition_sp_1 pb sp)))) interp).

      intros p' Hp'.
      apply SPWEqP.MP.Dec.F.mem_2 in Hp'.
      unfold partition_sp_1 in Hp'.
      apply SP.partition_spec2 in Hp'; try apply proper_8.
      apply SPWEqP.MP.Dec.F.filter_1 in Hp'; try apply proper_9.
      unfold sp_ok in HSPM.
      apply HSPM; try assumption.
      apply SPWEqP.MP.Dec.F.mem_1; assumption.

    clear HSPM.

    assert (HSPS' : sp_ok (SP.fold (subst_in_sp_aux_2 pa)
                         (snd_sp (partition_sp_2 pb (fst_sp (partition_sp_1 pb sp))))
                         SP.empty) interp).
    apply SPWEqP.MP.fold_rec_nodep; try apply sp_ok_empty.
    clear HIn.
    intros x a HInRec HSPRec.
    intros p' Hp'.
    unfold subst_in_sp_aux_2 in *.
    apply SPWEqP.MP.Dec.F.mem_2 in Hp'.
    rewrite SPWEqP.MP.Dec.F.add_iff in Hp'.
    elim Hp'; intro HIn; clear Hp'.

      destruct HIn as [HEq1 HEq2].
      rewrite <- HEq1; rewrite <- HEq2.
      unfold new_pair_2.
      clear HSPRec; clear a.
      elim (Pos.min_spec (fstpp(x)) pa); intro Hmin.

        destruct Hmin as [HLt Hmin].
        assert (Hmax : Pos.max (fstpp(x)) pa = pa) by (apply Pos.max_r; apply Pos.lt_le_incl; assumption).
        assert (HF : fstpp(fstpp(x), pa) = fstpp(x)) by (unfold fstpp; assumption).
        assert (HS : sndpp(fstpp(x), pa) = pa) by (unfold sndpp; assumption).
        rewrite HF; rewrite HS.

        assert (Hpb : sndpp(x) = pb).

          assert (HIn : SP.In x (fst_sp (partition_sp_1 pb sp))).

            unfold partition_sp_2 in HInRec.
            apply SP.partition_spec2 in HInRec; try apply proper_8.
            apply SPWEqP.MP.Dec.F.filter_1 in HInRec; try apply proper_9.
            assumption.

          unfold partition_sp_2 in HInRec.
          apply SP.partition_spec2 in HInRec; try apply proper_8.
          apply SPWEqP.MP.Dec.F.filter_2 in HInRec; try apply proper_9.
          unfold partition_sp_1 in HIn.
          apply SP.partition_spec1 in HIn; try apply proper_6.
          apply SPWEqP.MP.Dec.F.filter_2 in HIn; try apply proper_6.
          apply orb_true_iff in HIn.
          elim HIn; intro HEqb; clear HIn.

            apply Peqb_true_eq in HEqb.
            apply negb_true_iff in HInRec.
            apply Pos.eqb_neq in HInRec.
            rewrite HEqb in HInRec.
            intuition.

            apply Peqb_true_eq in HEqb.
            assumption.

        intro HEq4.
        unfold sp_ok in HSPS.
        apply SPWEqP.MP.Dec.F.mem_1 in HInRec.
        apply (HSPS x) in HInRec.
        apply HInRec.
        rewrite Hpb; rewrite HEq4; rewrite HA; rewrite HB; rewrite H; reflexivity.

        destruct Hmin as [HLe Hmin].
        assert (Hmax : Pos.max (fstpp(x)) pa = fstpp(x)) by (apply Pos.max_l; assumption).
        assert (HF : fstpp(fstpp(x), pa) = pa) by (unfold fstpp; assumption).
        assert (HS : sndpp(fstpp(x), pa) = fstpp(x)) by (unfold sndpp; assumption).
        rewrite HF; rewrite HS.

        assert (Hpb : sndpp(x) = pb).

          assert (HIn : SP.In x (fst_sp (partition_sp_1 pb sp))).

            unfold partition_sp_2 in HInRec.
            apply SP.partition_spec2 in HInRec; try apply proper_8.
            apply SPWEqP.MP.Dec.F.filter_1 in HInRec; try apply proper_9.
            assumption.

          unfold partition_sp_2 in HInRec.
          apply SP.partition_spec2 in HInRec; try apply proper_8.
          apply SPWEqP.MP.Dec.F.filter_2 in HInRec; try apply proper_9.
          unfold partition_sp_1 in HIn.
          apply SP.partition_spec1 in HIn; try apply proper_6.
          apply SPWEqP.MP.Dec.F.filter_2 in HIn; try apply proper_6.
          apply orb_true_iff in HIn.
          elim HIn; intro HEqb; clear HIn.

            apply Peqb_true_eq in HEqb.
            apply negb_true_iff in HInRec.
            apply Pos.eqb_neq in HInRec.
            rewrite HEqb in HInRec.
            intuition.

            apply Peqb_true_eq in HEqb.
            assumption.

        intro HEq4.
        unfold sp_ok in HSPS.
        apply SPWEqP.MP.Dec.F.mem_1 in HInRec.
        apply (HSPS x) in HInRec.
        apply HInRec.
        rewrite Hpb; rewrite <- HEq4; rewrite HA; rewrite HB; rewrite H; reflexivity.

      unfold sp_ok in HSPRec.
      apply HSPRec.
      apply SPWEqP.MP.Dec.F.mem_1; assumption.

    clear HSPS; assert (HSPS := HSPS'); clear HSPS'.
    unfold sp_ok in HSPS.
    apply HSPS.
    apply SPWEqP.MP.Dec.F.mem_1; assumption.

  assert (HIn := HInAux); clear HInAux.
  assert (HSPK : sp_ok (snd_sp (partition_sp_1 pb sp)) interp).

    intros p' Hp'.
    apply SPWEqP.MP.Dec.F.mem_2 in Hp'.
    unfold partition_sp_1 in Hp'.
    apply SP.partition_spec2 in Hp'; try apply proper_6.
    apply SPWEqP.MP.Dec.F.filter_1 in Hp'; try apply proper_7.
    unfold sp_ok in HSP.
    apply HSP; try assumption.
    apply SPWEqP.MP.Dec.F.mem_1; assumption.

  unfold sp_ok in HSPK.
  apply HSPK; try assumption.
  apply SPWEqP.MP.Dec.F.mem_1; assumption.
Qed.

End Col_refl.

Ltac add_to_distinct_list x xs :=
  match xs with
    | nil     => constr:(x::xs)
    | x::_    => fail 1
    | ?y::?ys => let zs := add_to_distinct_list x ys in constr:(y::zs)
  end.

Ltac collect_points_list Tpoint xs :=
  match goal with
    | N : Tpoint |- _ => let ys := add_to_distinct_list N xs in
                           collect_points_list Tpoint ys
    | _               => xs
  end.

Ltac collect_points Tpoint := collect_points_list Tpoint (@nil Tpoint).

Ltac number_aux Tpoint lvar cpt :=
  match constr:lvar with
    | nil          => constr:(@nil (prodT Tpoint positive))
    | cons ?H ?T => let scpt := eval vm_compute in (Pos.succ cpt) in
                    let lvar2 := number_aux Tpoint T scpt in
                      constr:(cons (@pairT  Tpoint positive H cpt) lvar2)
  end.

Ltac number Tpoint lvar := number_aux Tpoint lvar (1%positive).

Ltac build_numbered_points_list Tpoint := let lvar := collect_points Tpoint in number Tpoint lvar.

Ltac List_assoc Tpoint elt lst :=
  match constr:lst with
    | nil => fail
    | (cons (@pairT Tpoint positive ?X1 ?X2) ?X3) =>
      match constr:(elt = X1) with
        | (?X1 = ?X1) => constr:X2
        | _ => List_assoc Tpoint elt X3
      end
  end.

Ltac assert_ss_ok Tpoint Col lvar :=
  repeat
  match goal with
    | HCol : Col ?A ?B ?C, HOK : ss_ok ?SS ?Interp |- _ =>
        let pa := List_assoc Tpoint A lvar in
        let pb := List_assoc Tpoint B lvar in
        let pc := List_assoc Tpoint C lvar in
         apply (@Col_Col_tagged Tpoint Col) in HCol;
         apply (collect_cols A B C HCol pa pb pc SS Interp) in HOK; try reflexivity
  end.

Ltac assert_sp_ok Tpoint Col lvar :=
  repeat
  match goal with
    | HDiff : ?A <> ?B, HOK : sp_ok ?SP ?Interp |- _ =>
        let pa := List_assoc Tpoint A lvar in
        let pb := List_assoc Tpoint B lvar in
          apply (@Diff_Diff_tagged Tpoint) in HDiff;
          apply (collect_diffs A B HDiff pa pb SP Interp) in HOK; try reflexivity
  end.

Ltac subst_in_cols Tpoint Col :=
  repeat
  match goal with
    | HOKSS : ss_ok ?SS ?Interp, HOKSP : sp_ok ?SP ?Interp, HL : eq_tagged ?Lvar, HEQ : ?A = ?B |- _ =>
      let pa := List_assoc Tpoint A Lvar in
      let pb := List_assoc Tpoint B Lvar in
        apply (subst_ss_ok A B HEQ pa pb SS Interp) in HOKSS; try reflexivity;
        apply (subst_sp_ok A B HEQ pa pb SP Interp) in HOKSP; try reflexivity;
        subst B
  end.

Ltac clear_cols_aux Tpoint Col :=
  repeat
  match goal with
    | HOKSS : ss_ok ?SS ?Interp, HOKSP : sp_ok ?SP ?Interp, HL : eq_tagged ?Lvar |- _ =>
      clear HOKSS; clear HOKSP; clear HL
  end.

Ltac tag_hyps_gen Tpoint Col :=
  repeat
  match goal with
    | HDiff : ?A <> ?B |- _ => apply (@Diff_Diff_tagged Tpoint) in HDiff
    | HCol : Col ?A ?B ?C |- _ => apply (@Col_Col_tagged Tpoint Col) in HCol
  end.

Ltac untag_hyps_gen Tpoint Col :=
  repeat
  match goal with
    | HDiff : Diff_tagged ?A ?B |- _ => apply (@Diff_tagged_Diff Tpoint) in HDiff
    | HCol : Col_tagged ?A ?B ?C |- _ => apply (@Col_tagged_Col Tpoint Col) in HCol
  end.

(* TODO : move *)
(* Require Import tarski_to_col_theory. *)

Ltac show_all' :=
  repeat
  match goal with
    | Hhidden : Something |- _ => show Hhidden
  end.

Ltac clear_cols_gen Tpoint Col := show_all'; clear_cols_aux Tpoint Col.

Ltac Col_refl Tpoint Col :=
  match goal with
    | Default : Tpoint |- Col ?A ?B ?C =>
        let lvar := build_numbered_points_list Tpoint in
        let pa := List_assoc Tpoint A lvar in
        let pb := List_assoc Tpoint B lvar in
        let pc := List_assoc Tpoint C lvar in
        let c := ((vm_compute;reflexivity) || fail 2 "Can not be deduced") in
        let HSS := fresh in
          assert (HSS := @ss_ok_empty Tpoint Col (interp lvar Default)); assert_ss_ok Tpoint Col lvar;
        let HSP := fresh in
          assert (HSP := @sp_ok_empty Tpoint (interp lvar Default)); assert_sp_ok Tpoint Col lvar; 
          match goal with
            | HOKSS : ss_ok ?SS ?Interp, HOKSP : sp_ok ?SP ?Interp |- _ =>
              apply (test_col_ok SS SP (interp lvar Default) pa pb pc ); [assumption|assumption|c]
          end
  end.

(*
Ltac deduce_cols_aux Tpoint Col := 
  match goal with
    | Default : Tpoint |- _ =>
        let lvar := build_numbered_points_list Tpoint in
        let HSS := fresh in
          assert (HSS := @ss_ok_empty Tpoint Col (interp lvar Default)); assert_ss_ok Tpoint Col lvar;
        let HSP := fresh in
          assert (HSP := @sp_ok_empty Tpoint (interp lvar Default)); assert_sp_ok Tpoint Col lvar;
        let HL := fresh in
          assert (HL : lvar = lvar) by reflexivity;
          apply (@eq_eq_tagged Tpoint) in HL
  end.

Ltac deduce_cols Tpoint Col := deduce_cols_aux Tpoint Col.
*)

Ltac deduce_cols_hide_aux Tpoint Col := 
  match goal with
    | Default : Tpoint |- _ =>
        let lvar := build_numbered_points_list Tpoint in
        let HSS := fresh in
          assert (HSS := @ss_ok_empty Tpoint Col (interp lvar Default)); assert_ss_ok Tpoint Col lvar;
        let HSP := fresh in
          assert (HSP := @sp_ok_empty Tpoint (interp lvar Default)); assert_sp_ok Tpoint Col lvar;
        let HL := fresh in
          assert (HL : lvar = lvar) by reflexivity;
          apply (@eq_eq_tagged Tpoint) in HL;
          hide HSS; hide HSP; hide HL
  end.

Ltac deduce_cols_hide_gen Tpoint Col := deduce_cols_hide_aux Tpoint Col.

Ltac update_cols_aux Tpoint Col :=
  match goal with
    | HOKSS : ss_ok ?SS ?Interp, HOKSP : sp_ok ?SP ?Interp, HEQ : eq_tagged ?Lvar |- _ =>
      assert_ss_ok Tpoint Col Lvar; assert_sp_ok Tpoint Col Lvar; subst_in_cols Tpoint Col; hide HOKSS; hide HOKSP; hide HEQ
  end.

Ltac update_cols_gen Tpoint Col := show_all'; update_cols_aux Tpoint Col.

Ltac cols_aux Tpoint Col :=
  match goal with
    | HOKSS : ss_ok ?SS ?Interp, HOKSP : sp_ok ?SP ?Interp, HL : eq_tagged ?Lvar |- Col ?A ?B ?C =>
      let pa := List_assoc Tpoint A Lvar in
      let pb := List_assoc Tpoint B Lvar in
      let pc := List_assoc Tpoint C Lvar in
      let c := ((vm_compute;reflexivity) || fail 1 "Can not be deduced") in
        apply (test_col_ok SS SP Interp pa pb pc ); [assumption|assumption|c];
        hide HOKSS; hide HOKSP; hide HL
  end.

Ltac cols_gen Tpoint Col := show_all'; cols_aux Tpoint Col.

Ltac Col_refl_test Tpoint Col := deduce_cols_hide_gen Tpoint Col; cols_gen Tpoint Col.

(*
Section Test.

Context `{MT:Tarski_neutral_dimensionless}.
Context `{EqDec:EqDecidability Tpoint}.

Goal forall Q R A B C D E F G H I J K L M N,
  False -> L = M -> D <> E -> J <> K -> Q <> R -> G <> H -> 
  Col Q R A -> Col Q R B -> Col Q R C ->
  Col Q R D -> Col Q R E -> Col Q R F ->
  Col G H I -> Col G I J -> Col A B K ->
  Col I J K -> Col L M N -> Col K L M ->
  Col Q A B /\ Col Q F E /\ Col Q J M.
Proof.
intros.
split.
Time Col_refl Tpoint Col.
Time deduce_cols_hide_gen Tpoint Col.
show_all'.
subst_in_cols Tpoint Col.
repeat split.
Time cols_gen Tpoint Col.
Time (cols_gen Tpoint Col||intuition).
Qed.

End Test.
*)